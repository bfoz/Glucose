//
//  ExportViewController.m
//  Glucose
//
//  Created by Brandon Fosdick on 9/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//


#import "AppDelegate.h"
#import "Category.h"
#import "Constants.h"
#import "Contact.h"
#import "InsulinType.h"
#import "LogEntry.h"
#import "LogModel.h"

#import "ExportViewController.h"
#import "ContactListViewController.h"

#import "GDataACL.h"
#import "GDataDocs.h"

#import <Security/Security.h>

#if TARGET_IPHONE_SIMULATOR
#define	kGoogleDocUserName	@"GoogleDocUserName"
#define kGoogleDocPassword	@"GoogleDocPassword"
#define	kSecAttrAccount	@"kSecAttrAccount"
#define	kSecValueData	@"kSecValueData"
#endif // TARGET_IPHONE_SIMULATOR

#define	kGoogleExportFolder	@"Glucose Export"

#define	GENERIC_PASSWORD	0

#define	SECTION_ACCOUNT		0
#define	SECTION_DATE_RANGE	1
#define	SECTION_SHARE		2
#define	SECTION_EXPORT		3

@implementation ExportViewController

static const uint8_t kKeychainItemIdentifier[]	= "com.google.docs";

@synthesize keychainData, failureTitle;
@synthesize model;

- (id)initWithStyle:(UITableViewStyle)style
{
	if( self = [super initWithStyle:style] )
	{
		self.title = @"Export";

		// exportStart defaults to the day after the last export
		//  or the beginning of the LogEntry table if no last export
		NSUserDefaults *const defaults = [NSUserDefaults standardUserDefaults];
		exportStart = [defaults objectForKey:kLastExportGoogleToDate];
		// If the value exists, add one day and use it. Otherwise, use the 
		//  timestamp from the first record in the database.
		if( exportStart )
			exportStart = [exportStart addTimeInterval:24*60*60];
		else
		{
			exportStart = [appDelegate earliestLogEntryDate];
			if( !exportStart )
				exportStart = [NSDate date];
		}
		exportEnd = [NSDate date];
		[exportEnd retain];
		[exportStart retain];

		shareSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
		shareSwitch.on = [defaults boolForKey:kExportGoogleShareEnable];
		[shareSwitch addTarget:self action:@selector(shareSwitchAction) forControlEvents:UIControlEventValueChanged];

		showingContacts = NO;
		[self keychainInit];
	}
	return self;
}

- (void) loadView
{
	[super loadView];
	self.tableView.scrollEnabled = NO;	// Disable scrolling
}

- (void)dealloc
{
	[exportEnd release];
	[exportStart release];
	[exportLastField release];
	[gDocPasswordQuery release];
	[keychainData release];
	[progressAlert release];
	[progressView release];
	[shareSwitch release];
	[super dealloc];
}

- (void) loadContactList
{
	if( contacts && (0 == [contacts count]) )
	{
		NSUserDefaults *const defaults = [NSUserDefaults standardUserDefaults];
		NSArray* email = [defaults arrayForKey:kExportGoogleShareEmailList];
		NSArray* records = [defaults arrayForKey:kExportGoogleShareRecordList];

		if( email && records )
		{
			NSAssert([email count]==[records count], @"Email array count != Record array count");
			
			NSEnumerator* i = [email objectEnumerator];
			NSEnumerator* j = [records objectEnumerator];
			NSNumber* e = nil;
			NSNumber* r = nil;
			while( (e = [i nextObject]) && (r = [j nextObject]) )
			{
				Contact* c = [[Contact alloc] initWithRecordID:[r intValue] emailID:[e intValue]];
				[contacts addObject:c];
		[c release];
			}
		}
	}
}

- (void) saveContactList
{
	NSUserDefaults *const defaults = [NSUserDefaults standardUserDefaults];
	NSMutableArray* records = [[NSMutableArray alloc] init];
	NSMutableArray* email = [[NSMutableArray alloc] init];
	for( Contact* c in contacts )
	{
		[records addObject:[NSNumber numberWithInt:c.recordID]];
		[email addObject:[NSNumber numberWithInt:c.emailID]];
	}
	[defaults setObject:email forKey:kExportGoogleShareEmailList];
	[defaults setObject:records forKey:kExportGoogleShareRecordList];
	[email release];
	[records release];
}

- (void) shareSwitchAction
{
	[[NSUserDefaults standardUserDefaults] setBool:shareSwitch.on forKey:kExportGoogleShareEnable];
}

- (void) viewDidAppear:(BOOL)animated
{
	if( showingContacts )
	{
		[self saveContactList];
		if( ![contacts count] )
		{
			// Animate this so the user can see what happened
			[shareSwitch setOn:NO animated:YES];
			[self shareSwitchAction];	// setOn:animated: doesn't generate an action
		}
		showingContacts = NO;
	}
}

#pragma mark -
#pragma mark Keychain Wrangling

#if !TARGET_IPHONE_SIMULATOR
// Do some common initialization stuff on the provided dictionary
- (void) commonKeychainInit:(NSMutableDictionary*)d
{
#if GENERIC_PASSWORD
	// Add the Keychain Item class as well as the generic attribute.
	NSData *keychainType = [NSData dataWithBytes:kKeychainItemIdentifier length:strlen((const char *)kKeychainItemIdentifier)];
	[d setObject:keychainType forKey:(id)kSecAttrGeneric];
	[d setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
#else
	[d setObject:(id)kSecClassInternetPassword forKey:(id)kSecClass];
	[d setObject:[[NSURL URLWithString:kGDataGoogleDocsDefaultPrivateFullFeed] path] forKey:(id)kSecAttrPath];
	[d setObject:(id)kSecAttrProtocolHTTP forKey:(id)kSecAttrProtocol];
	[d setObject:@"docs.google.com" forKey:(id)kSecAttrServer];
#endif	// GENERIC_PASSWORD
}
#endif	// !TARGET_IPHONE_SIMULATOR

- (void) keychainInit
{
#if TARGET_IPHONE_SIMULATOR
	self.keychainData = [[NSMutableDictionary alloc] init];
	NSUserDefaults *const defaults = [NSUserDefaults standardUserDefaults];
	NSString *const userName = [defaults stringForKey:kGoogleDocUserName];
	if( userName )
		[keychainData setObject:userName forKey:kSecAttrAccount];	// Username
	NSString *const password = [defaults stringForKey:kGoogleDocPassword];
	if( password )
		[keychainData setObject:password forKey:kSecValueData];	// Password
#else
	// Set up the keychain search dictionary
	if( !gDocPasswordQuery )
		gDocPasswordQuery = [[NSMutableDictionary alloc] init];
	[self commonKeychainInit:gDocPasswordQuery];

	// Return the attributes of the first match only:
	[gDocPasswordQuery setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];
	// Return the attributes of the keychain item (the password is
	//  acquired in the secItemFormatToDictionary: method):
	[gDocPasswordQuery setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnAttributes];
	
	//Initialize the dictionary used to hold return data from the keychain:
	NSMutableDictionary *outDictionary = nil;
	NSDictionary *tempQuery = [NSDictionary dictionaryWithDictionary:gDocPasswordQuery];
	
	// If a keychain item exists, use it to populate keychainData. Otherwise,
	//  create a default keychain item in keychainData
	if( SecItemCopyMatching((CFDictionaryRef)tempQuery, (CFTypeRef *)&outDictionary) == noErr )
		self.keychainData = [self secItemFormatToDictionary:outDictionary];
	else
	{
		self.keychainData = [[NSMutableDictionary alloc] init];
		
		// Default data for Keychain Item.
		[keychainData setObject:@"" forKey:(id)kSecAttrAccount];	// Username
		[keychainData setObject:@"" forKey:(id)kSecValueData];		// Password
	}
	
	[outDictionary release];
#endif	// TARGET_IPHONE_SIMULATOR
}

#if !TARGET_IPHONE_SIMULATOR
- (NSMutableDictionary *)dictionaryToSecItemFormat:(NSDictionary *)dictionaryToConvert
{
    // The assumption is that this method will be called with a properly populated dictionary
    // containing all the right key/value pairs for a SecItem.
    
    // Create returning dictionary populated with the attributes.
    NSMutableDictionary *returnDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionaryToConvert];
	[self commonKeychainInit:returnDictionary];

    // Convert the NSString to NSData to fit the API paradigm.
    NSString *passwordString = [dictionaryToConvert objectForKey:(id)kSecValueData];
    [returnDictionary setObject:[passwordString dataUsingEncoding:NSUTF8StringEncoding] forKey:(id)kSecValueData];
    
    return returnDictionary;
}

- (NSMutableDictionary *)secItemFormatToDictionary:(NSDictionary *)dictionaryToConvert
{
    // The assumption is that this method will be called with a properly populated dictionary
    // containing all the right key/value pairs for the UI element.
    
    // Remove the generic attribute which distinguishes this Keychain Item with this
    // application.
    // Create returning dictionary populated with the attributes.
    NSMutableDictionary *returnDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionaryToConvert];
    
    // Add the proper search key and class attribute.
    [returnDictionary setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
	[returnDictionary setObject:[gDocPasswordQuery objectForKey:(id)kSecClass] forKey:(id)kSecClass];

    // Acquire the password data from the attributes.
    NSData *passwordData = NULL;
    if (SecItemCopyMatching((CFDictionaryRef)returnDictionary, (CFTypeRef *)&passwordData) == noErr)
    {
        // Remove the search, class, and identifier key/value, we don't need them anymore.
        [returnDictionary removeObjectForKey:(id)kSecReturnData];
		[returnDictionary removeObjectForKey:(id)kSecClass];
        
        // Add the password to the dictionary.
        NSString *password = [[[NSString alloc] initWithBytes:[passwordData bytes] length:[passwordData length] 
                                                     encoding:NSUTF8StringEncoding] autorelease];
        [returnDictionary setObject:password forKey:(id)kSecValueData];
    }
    else
    {
        // Don't do anything if nothing is found.
        NSAssert(NO, @"Serious error, nothing is found in the Keychain.\n");
    }
    
    [passwordData release];
    return returnDictionary;
}
#endif	// !TARGET_IPHONE_SIMULATOR

- (void)writeToKeychain
{
#if TARGET_IPHONE_SIMULATOR
	[[NSUserDefaults standardUserDefaults] setObject:usernameField.text forKey:kGoogleDocUserName];
	[[NSUserDefaults standardUserDefaults] setObject:passwordField.text forKey:kGoogleDocPassword];
#else
    NSDictionary *attributes = NULL;
    NSMutableDictionary *updateItem = NULL;
    
	// If the keychain item already exists, update it. Otherwise, create a new item.
    if (SecItemCopyMatching((CFDictionaryRef)gDocPasswordQuery, (CFTypeRef *)&attributes) == noErr)
    {
        // Create the item specification for the existing item from the retrieved attributes
        updateItem = [NSMutableDictionary dictionaryWithDictionary:attributes];
        // Add the appropriate class key to the item specification
        [updateItem setObject:[gDocPasswordQuery objectForKey:(id)kSecClass] forKey:(id)kSecClass];
        
        // Munge the new keychain data into a list of attributes to be updated
        NSMutableDictionary *tempCheck = [self dictionaryToSecItemFormat:keychainData];
		// Remove the class key from the list
        [tempCheck removeObjectForKey:(id)kSecClass];
        
        // An implicit assumption is that you can only update a single item at a time.
        NSAssert( SecItemUpdate((CFDictionaryRef)updateItem, (CFDictionaryRef)tempCheck) == noErr, 
                 @"Couldn't update the Keychain Item." );
    }
    else
    {
        // No previous item found, add the new one.
        NSAssert( SecItemAdd((CFDictionaryRef)[self dictionaryToSecItemFormat:keychainData], NULL) == noErr, 
                 @"Couldn't add the Keychain Item." );
    }
#endif // TARGET_IPHONE_SIMULATOR
}

#pragma mark -
#pragma mark <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch( section )
	{
		case 0: return 2;	// Account info
		case 1: return 2;	// Date range
		case 2: return 1;	// Sharing
		case 3: return 1;	// Export button
	}
	return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{	
	NSString* cellID;
	const unsigned	row		= indexPath.row;
	const unsigned	section	= indexPath.section;

	switch( section )
	{
	case 1: cellID = @"DateRange"; break;
		case 2: cellID = @"Share"; break;
		case 3: cellID = @"Export"; break;
		default: cellID = @"CellID"; break;
	}

	UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:cellID];
	if( !cell )
	{
	if( 1 == section )	// Use an attribute-style cell
	    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellID] autorelease];
	else
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}

	UITextField*	f	= nil;
	switch( section )
	{
		case 0:
			switch( row )
			{
				case 0:
					cell.textLabel.text = @"Username";
					f = [[UITextField alloc] initWithFrame:CGRectMake(0, kCellTopOffset*2, 175, 20)];
					f.clearButtonMode = UITextFieldViewModeWhileEditing;
					f.delegate = self;
					f.returnKeyType = UIReturnKeyDone;
					f.textAlignment = UITextAlignmentRight;
					f.text = [self.keychainData objectForKey:(id)kSecAttrAccount];
					cell.accessoryView = f;
					usernameCell = cell;
					usernameField = f;
					break;
				case 1:
					cell.textLabel.text = @"Password";
					f = [[UITextField alloc] initWithFrame:CGRectMake(0, kCellTopOffset*2, 175, 20)];
					f.clearButtonMode = UITextFieldViewModeWhileEditing;
					f.delegate = self;
					f.returnKeyType = UIReturnKeyDone;
					f.secureTextEntry = YES;
					f.textAlignment = UITextAlignmentRight;
					f.text = [self.keychainData objectForKey:(id)kSecValueData];
					cell.accessoryView = f;
					passwordCell = cell;
					passwordField = f;
					break;
			}
			break;
		case 1:
		{
			switch( row )
			{
				case 0:
					// The From field defaults to the day after the last export
					//  or the beginning of the LogEntry table if no last export
					cell.textLabel.text = @"From";
					cell.detailTextLabel.text = [shortDateFormatter stringFromDate:exportStart];
					exportStartField = cell.detailTextLabel;
					exportStartCell = cell;
					break;
				case 1:
					// The To field defaults to Today
					cell.textLabel.text = @"To";
					cell.detailTextLabel.text = @"Today";
					exportEndField = cell.detailTextLabel;
					exportEndCell = cell;
					break;
			}
			break;
		}
		case 2:
			cell.textLabel.text = @"Share Exported File";
			cell.accessoryView = shareSwitch;
			break;
		case 3:
			switch( row )
			{
				case 0:
					cell.textLabel.textAlignment = UITextAlignmentCenter;
					exportCell = cell;
					[self updateExportRowText];
					break;
			}
	}
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if( SECTION_EXPORT == section )
    {
	NSUserDefaults *const defaults = [NSUserDefaults standardUserDefaults];
	NSDate *const lastExportStart = [defaults objectForKey:kLastExportGoogleFromDate];
	NSDate *const lastExportEnd = [defaults objectForKey:kLastExportGoogleToDate];
	NSDate *const lastExportedOn = [defaults objectForKey:kLastExportGoogleOnDate];

	if( lastExportStart && lastExportEnd && lastExportedOn )
	    return [NSString stringWithFormat:@"Last exported from %@ to %@ on %@", [shortDateFormatter stringFromDate:lastExportStart], [shortDateFormatter stringFromDate:lastExportEnd], [shortDateFormatter stringFromDate:lastExportedOn]];
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)section
{
    switch( section )
	{
        case 0: return @"Google Account Information";
    }
    return nil;
}

#pragma mark -
#pragma mark <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	const unsigned section = indexPath.section;
	if( section == SECTION_ACCOUNT )
	{
		switch( indexPath.row )
		{
			case 0: [usernameField becomeFirstResponder]; break;
			case 1: [passwordField becomeFirstResponder]; break;
		}
	}
	else if( section == SECTION_DATE_RANGE )
	{
		switch( indexPath.row )
		{
	    case 0: [self toggleDatePicker:exportStartCell mode:UIDatePickerModeDate initialDate:exportStart changeAction:@selector(exportStartChangeAction)]; break;
	    case 1: [self toggleDatePicker:exportEndCell mode:UIDatePickerModeDate initialDate:exportEnd changeAction:@selector(exportEndChangeAction)]; break;
		}
	}
	else if( section == SECTION_SHARE )
	{
		if( !shareSwitch.on )
		{
			[shareSwitch setOn:YES animated:YES];
			[self shareSwitchAction];	// Fake an action message to update settings
		}
		if( !contacts )
			contacts = [[NSMutableArray alloc] init];
		[self loadContactList];
		ContactListViewController* clvc = [[ContactListViewController alloc] initWithStyle:UITableViewStyleGrouped];
		clvc.contacts = contacts;
		[self.navigationController pushViewController:clvc animated:YES];
		[clvc setEditing:YES animated:NO];
	    [clvc release];
		showingContacts = YES;
	}
	else if( (section == SECTION_EXPORT) && exportEnabled )
	{
		// Refresh the service object's credentials in case they've changed
		[appDelegate setUserCredentialsWithUsername:usernameField.text
										   password:passwordField.text];

		// Create an alert for displaying a progress bar while uploading
		progressAlert = [[UIAlertView alloc] initWithTitle:@"Exporting..." message:@"Fetching DocFeed"
													   delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
		// Add a progress bar to the alert
		progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(30,80,225,90)];
		[progressAlert addSubview:progressView];
		[progressView setProgressViewStyle:UIProgressViewStyleDefault];
		[progressAlert show];

		// Show the network activity indicator
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	[self findExportFolder];
	}
}

#pragma mark -
#pragma mark Google Doc Export

- (void) cleanupExport
{
	if( contactsEnumerator )
	{
		[contactsEnumerator release];
		contactsEnumerator = nil;
	}
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[progressAlert dismissWithClickedButtonIndex:0 animated:YES];
}

- (void) finishExport
{
	NSUserDefaults *const defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:[NSDate date] forKey:kLastExportGoogleOnDate];
	[defaults setObject:exportStart forKey:kLastExportGoogleFromDate];
	[defaults setObject:exportEnd forKey:kLastExportGoogleToDate];
	// Update the "Last Export On" row
	exportLastField.text = [shortDateFormatter stringFromDate:[NSDate date]];
	
    // Update the footer text
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SECTION_EXPORT]
		  withRowAnimation:NO];

	[self cleanupExport];
}

- (void) updateExportRowText
{
	unsigned num = [appDelegate numLogEntriesFrom:exportStart to:exportEnd];
	if( num )
	{
		exportCell.textLabel.text = [NSString stringWithFormat:@"Export %d Records", num];
		exportCell.textLabel.textColor = [UIColor blackColor];
		exportEnabled = YES;
	}
	else
	{
		exportCell.textLabel.text = @"Empty Date Range Selected";
		exportCell.textLabel.textColor = [UIColor grayColor];
		exportEnabled = NO;
	}
}

- (void) exportFail:(NSString*)title message:(NSString*)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
						    message:message
						   delegate:self
					  cancelButtonTitle:@"OK"
					  otherButtonTitles: nil];
    [alert show];
    [alert release];
    [self cleanupExport];
}

- (void) ticket:(GDataServiceTicket *)ticket failedWithError:(NSError *)error
{
    [self exportFail:failureTitle message:[error localizedDescription]];
}

#pragma mark Folder Handling

- (void) exportToFolderDoc:(GDataEntryFolderDoc*)folder
{
    self.failureTitle = @"Folder Feed";
    [appDelegate.docService fetchFeedWithURL:[GDataServiceGoogleDocs folderContentsFeedURLForFolderID:[folder resourceID]]
				    delegate:self
			   didFinishSelector:@selector(docsFeedTicket:finishedWithFeed:error:)];
}

- (void) createFolder:(NSString*)name url:(NSURL*)url
{
    // add a category that includes a "folder" label to work around the server issue
    GDataCategory *category = [GDataCategory categoryWithScheme:kGDataCategoryScheme
							   term:kGDataCategoryFolderDoc];
    [category setLabel:@"folder"];

    GDataEntryFolderDoc *docEntry = [GDataEntryFolderDoc documentEntry];
    [docEntry setCategories:[NSArray arrayWithObject:category]];
    [docEntry setTitleWithString:name];

    progressAlert.message = [NSString stringWithFormat:@"Creating folder '%@'", kGoogleExportFolder];
    self.failureTitle = @"Folder Create Failure";
    [appDelegate.docService fetchEntryByInsertingEntry:docEntry
					    forFeedURL:url
					      delegate:self
				     didFinishSelector:@selector(createFolderTicket:finishedWithEntry:error:)];
}

- (void) createFolderTicket:(GDataServiceTicket *)ticket finishedWithEntry:(GDataEntryFolderDoc *)folder error:(NSError *)error
{
    if( error )
	[self ticket:ticket failedWithError:error];
    else
	[self exportToFolderDoc:folder];
}

- (void) findExportFolder
{
    GDataQueryDocs *const q = [GDataQueryDocs documentQueryWithFeedURL:[GDataServiceGoogleDocs docsFeedURL]];
    q.titleQuery = @"Glucose Export";
    q.isTitleQueryExact = YES;
    q.shouldShowFolders = YES;
    q.maxResults = 1;

    progressAlert.message = @"Fetching Folder Feed";
    self.failureTitle = @"Find Export Folder";
    [appDelegate.docService fetchFeedWithQuery:q
				      delegate:self
			     didFinishSelector:@selector(findExportFolderTicket:finishedWithFeed:error:)];
}

- (void) findExportFolderTicket:(GDataServiceTicket *)ticket finishedWithFeed:(GDataFeedDocList *)feed error:(NSError *)error
{
    if( error )
    {
	[self ticket:ticket failedWithError:error];
	return;
    }

    unsigned count = [[feed entries] count];
    if( 0 == count )	// Create a new folder if none was found
	[self createFolder:kGoogleExportFolder url:[[feed postLink] URL]];
    else if( count > 1 )
	[self exportFail:failureTitle message:@"Too many folders returned"];
    else
	[self exportToFolderDoc:[[feed entries] objectAtIndex:0]];
}

#pragma mark Document List feed

- (void) docsFeedTicket:(GDataServiceTicket *)ticket finishedWithFeed:(GDataFeedDocList *)feed error:(NSError *)error
{
    if( error )
    {
	[self ticket:ticket failedWithError:error];
	return;
    }

    NSData *const data = [LogEntry createCSV:model.database from:exportStart to:exportEnd];
    if( !data )
    {
	[self cleanupExport];
	return;
    }

    NSString *const title = [NSString stringWithFormat:@"Glucose Export from %@ to %@", [shortDateFormatter stringFromDate:exportStart], [shortDateFormatter stringFromDate:exportEnd], nil];

    GDataEntryDocBase *docEntry = [GDataEntrySpreadsheetDoc documentEntry];
    [docEntry setUploadMIMEType:@"text/csv"];
    [docEntry setTitleWithString:title];
    [docEntry setUploadData:data];
    [docEntry setUploadSlug:title];

	GDataServiceGoogleDocs *const service = appDelegate.docService;
	
    // Have new service tickets call back into an upload progress selector
	SEL progressSel = @selector(ticket:hasDeliveredByteCount:ofTotalByteCount:);
	[service setServiceUploadProgressSelector:progressSel];

	// Do the insert
	self.failureTitle = @"Export Failed";
	[service fetchEntryByInsertingEntry:docEntry
				 forFeedURL:[[feed uploadLink] URL]
				   delegate:self
			  didFinishSelector:@selector(uploadFileTicket:finishedWithEntry:error:)];

	// Disable the progress callback for new tickets
	[service setServiceUploadProgressSelector:nil];
}

#pragma mark File Upload

// progress callback
- (void) ticket:(GDataServiceTicket *)ticket hasDeliveredByteCount:(unsigned long long)numberOfBytesRead ofTotalByteCount:(unsigned long long)dataLength
{
	progressAlert.message = [NSString stringWithFormat:@"Exported %qu of %qu bytes", numberOfBytesRead, dataLength];
	progressView.progress = ((float)numberOfBytesRead)/dataLength;
}

// The spreadsheet has been successfuly uploaded. Now update the ACL entryies if
//  sharing has been enabled, otherwise clean up and return
- (void)uploadFileTicket:(GDataServiceTicket *)ticket finishedWithEntry:(GDataEntryDocBase *)entry error:(NSError *)error
{
    if( error )
    {
	[self ticket:ticket failedWithError:error];
	return;
    }

    if( !shareSwitch.on )
	{
		[self finishExport];
		return;
	}

	if( !contacts )
		contacts = [[NSMutableArray alloc] init];
	[self loadContactList];
	if( [contacts count] )
	{
	self.failureTitle = @"ACL Feed Failed";
	[appDelegate.docService fetchACLFeedWithURL:[[entry ACLFeedLink] URL]
					   delegate:self
				  didFinishSelector:@selector(aclTicket:finishedWithFeed:error:)];
	}
}

#pragma mark ACL feed

- (void)aclTicket:(GDataServiceTicket *)ticket finishedWithFeed:(GDataFeedACL*)object error:(NSError *)error
{
    if( error )
    {
	[self ticket:ticket failedWithError:error];
	return;
    }

    aclURL = [[object postLink] URL];
    [self addACLTicket:nil finishedWithEntry:nil error:nil];
}

#pragma mark Add ACL Entries

- (void) addACLTicket:(GDataServiceTicket *)ticket finishedWithEntry:(GDataFeedACL*)object error:(NSError *)error
{
    if( error )
    {
	[self ticket:ticket failedWithError:error];
	return;
    }

	if( !contactsEnumerator )
	{
		contactsEnumerator = [contacts objectEnumerator];
		[contactsEnumerator retain];
	}
	Contact* c;
	if( c = [contactsEnumerator nextObject] )
	{
		ABAddressBookRef book = ABAddressBookCreate();

		ABRecordRef person = ABAddressBookGetPersonWithRecordID(book, c.recordID);
	    CFRetain(person);
	    CFRelease(book);
		ABMultiValueRef email = ABRecordCopyValue(person, kABPersonEmailProperty);
		CFIndex i = ABMultiValueGetIndexForIdentifier(email, c.emailID);
		CFTypeRef v = ABMultiValueCopyValueAtIndex(email, i);

		progressAlert.message = [NSString stringWithFormat:@"Sharing with %@", v];

		GDataACLRole* role = [GDataACLRole roleWithValue:kGDataRoleReader];
		GDataACLScope* scope = [GDataACLScope scopeWithType:kGDataScopeTypeUser value:(NSString*)v];
		GDataEntryACL* acl = [GDataEntryACL ACLEntryWithScope:scope role:role];

		GDataServiceGoogleDocs *const service = appDelegate.docService;
		self.failureTitle = @"Share Failed";
	[service fetchACLEntryByInsertingEntry:acl
				    forFeedURL:aclURL
				      delegate:self
			     didFinishSelector:@selector(addACLTicket:finishedWithEntry:error:)];

		CFRelease(v);
		CFRelease(email);
		CFRelease(person);
	}
	else
		[self finishExport];
}

#pragma mark -
#pragma mark <UITextFieldDelegate>

- (UITableViewCell*) cellForField:(UITextField*)field
{
	if( field == usernameField )
		return usernameCell;
	else if( field == passwordField )
		return passwordCell;
	return nil;
}

- (SEL) selectorForField:(UITextField*)field
{
	if( field == usernameField )
		return @selector(saveUsernameAction);
	else if( field == passwordField )
		return @selector(savePasswordAction);
	return nil;
}

- (void)textFieldDidBeginEditing:(UITextField*)field
{
	[self didBeginEditing:[self cellForField:field] field:field action:[self selectorForField:field]];
}

- (void)textFieldDidEndEditing:(UITextField*)field
{
    if( self.navigationItem.rightBarButtonItem )
	[self performSelector:self.navigationItem.rightBarButtonItem.action];
}

- (BOOL) textFieldShouldReturn:(UITextField*)textField
{
    if( self.navigationItem.rightBarButtonItem )
	[self performSelector:self.navigationItem.rightBarButtonItem.action];
	return NO;
}

- (void)saveUsernameAction
{
	// Append @gmail.com if no domain was supplied
	if( [usernameField.text rangeOfString:@"@"].location == NSNotFound )
		usernameField.text = [usernameField.text stringByAppendingString:@"@gmail.com"];

	[keychainData setObject:usernameField.text forKey:(id)kSecAttrAccount];	// Username
	[self writeToKeychain];
	[self saveAction];
}

- (void)savePasswordAction
{
	[keychainData setObject:passwordField.text forKey:(id)kSecValueData];	// Password
	[self writeToKeychain];
	[self saveAction];
}

#pragma mark -
#pragma mark Date/Time Picker

- (void) exportStartChangeAction
{
	[exportStart release];
	exportStart = datePicker.date;
	[exportStart retain];
	exportStartField.text = [shortDateFormatter stringFromDate:exportStart];
	[self updateExportRowText];
	[[NSUserDefaults standardUserDefaults] setObject:exportStart forKey:kLastExportGoogleFromDate];
}

- (void) exportEndChangeAction
{
	[exportEnd release];
	exportEnd = datePicker.date;
	[exportEnd retain];
	exportEndField.text = [shortDateFormatter stringFromDate:exportEnd];
	[self updateExportRowText];
	[[NSUserDefaults standardUserDefaults] setObject:exportEnd forKey:kLastExportGoogleToDate];
}

@end

