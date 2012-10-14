#import "AppDelegate.h"

#import <DropboxSDK/DropboxSDK.h>

#import "Category.h"
#import "Constants.h"
#import "Contact.h"
#import "InsulinType.h"
#import "LogEntry.h"
#import "LogModel.h"

#import "ExportViewController.h"
#import "ContactListViewController.h"

#import <Security/Security.h>

#if TARGET_IPHONE_SIMULATOR
#define	kGoogleDocUserName	@"GoogleDocUserName"
#define kGoogleDocPassword	@"GoogleDocPassword"
#define	kSecAttrAccount	@"kSecAttrAccount"
#define	kSecValueData	@"kSecValueData"
#endif // TARGET_IPHONE_SIMULATOR

#define	kGoogleExportFolder	@"Glucose Export"

#define	GENERIC_PASSWORD	0

enum Sections
{
    kSectionDropBox = 0,
    kSectionDateRange,
    kSectionShare,
    kSectionExport,
    NUM_SECTIONS
};

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
			exportStart = [exportStart dateByAddingTimeInterval:24*60*60];
		else
		{
			exportStart = [appDelegate earliestLogEntryDate];
			if( !exportStart )
				exportStart = [NSDate date];
		}
		exportEnd = [NSDate date];

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

- (void) viewDidLoad
{
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dropboxSessionLinkedAccount:) name:kDropboxSessionLinkedAccountNotification object:nil];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
	[d setObject:[[GDataServiceGoogleDocs docsFeedURL] path] forKey:(id)kSecAttrPath];
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

#pragma mark - <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return NUM_SECTIONS;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch( section )
    {
	case kSectionDropBox:
	{
	    DBSession *const session = [DBSession sharedSession];
	    return [session isLinked] ? session.userIds.count+1 : 1;
	}
	case 1: return 2;	// Date range
	case 2: return 1;	// Sharing
	case 3: return 1;	// Export button
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{	
    NSString* cellID = @"cellID";
    const unsigned row	    = indexPath.row;
    const unsigned section  = indexPath.section;

	switch( section )
	{
	case 1: cellID = @"DateRange"; break;
		case 2: cellID = @"Share"; break;
		case 3: cellID = @"Export"; break;
	}

    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:cellID];
	if( !cell )
	{
	if( 1 == section )	// Use an attribute-style cell
	    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellID];
	else
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}

    switch( section )
    {
	case kSectionDropBox:
	{
	    DBSession* session = [DBSession sharedSession];
	    if( session.isLinked )
	    {
		if( session.userIds.count == row )
		{
		    cell.textLabel.text = @"Link another Dropbox account";
		    cell.textLabel.textAlignment = UITextAlignmentCenter;
		    cell.textLabel.textColor = [UIColor blueColor];
		    cell.textLabel.font = [UIFont italicSystemFontOfSize:[UIFont systemFontSize]];
		}
		else
		{
		    cell.textLabel.text = [NSString stringWithFormat:@"Export to account %@", [session.userIds objectAtIndex:row]];
		    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
	    }
	    else
	    {
		cell.textLabel.text = @"Link your Dropbox account";
		cell.textLabel.textAlignment = UITextAlignmentCenter;
	    }
	    break;
	}
		case 1:
		{
			switch( row )
			{
				case 0:
					// The From field defaults to the day after the last export
					//  or the beginning of the LogEntry table if no last export
					cell.textLabel.text = @"From";
					cell.detailTextLabel.text = [model shortStringFromDate:exportStart];
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
    if( kSectionDropBox == section )
    {
	return @"Linking a Dropbox account allows you to export your data to a folder in your Dropbox";
    }
    else if( kSectionExport == section )
    {
	NSUserDefaults *const defaults = [NSUserDefaults standardUserDefaults];
	NSDate *const lastExportStart = [defaults objectForKey:kLastExportGoogleFromDate];
	NSDate *const lastExportEnd = [defaults objectForKey:kLastExportGoogleToDate];
	NSDate *const lastExportedOn = [defaults objectForKey:kLastExportGoogleOnDate];

	if( lastExportStart && lastExportEnd && lastExportedOn )
	{
	    NSString* stringLastExportStart = [model shortStringFromDate:lastExportStart];
	    NSString* stringLastExportEnd = [model shortStringFromDate:lastExportEnd];
	    NSString* stringLastExportedOn = [model shortStringFromDate:lastExportedOn];
	    if( stringLastExportStart && stringLastExportEnd && stringLastExportedOn )
		return [NSString stringWithFormat:@"Last exported from %@ to %@ on %@", stringLastExportStart, stringLastExportEnd, stringLastExportedOn];
	}
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)section
{
    switch( section )
    {
        case 0: return @"Dropbox";
    }
    return nil;
}

#pragma mark -
#pragma mark <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    const unsigned section = indexPath.section;
    if( section == kSectionDropBox )
    {
	DBSession* session = [DBSession sharedSession];
	if( session.isLinked )
	{
	    // FIXME: Push a DropboxExportViewController
	}
	else if( session.userIds.count == indexPath.row )
	{
	    [[DBSession sharedSession] linkFromController:self];
	}
    }
	else if( section == kSectionDateRange )
	{
		switch( indexPath.row )
		{
	    case 0: [self toggleDatePicker:exportStartCell mode:UIDatePickerModeDate initialDate:exportStart changeAction:@selector(exportStartChangeAction)]; break;
	    case 1: [self toggleDatePicker:exportEndCell mode:UIDatePickerModeDate initialDate:exportEnd changeAction:@selector(exportEndChangeAction)]; break;
		}
	}
	else if( section == kSectionShare )
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
		showingContacts = YES;
	}
	else if( (section == kSectionExport) && exportEnabled )
	{
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
	}
}

- (void) cleanupExport
{
	if( contactsEnumerator )
	{
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
	exportLastField.text = [model shortStringFromDate:[NSDate date]];
	
    // Update the footer text
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kSectionExport]
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
    [self cleanupExport];
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
	exportStart = datePicker.date;
	exportStartField.text = [model shortStringFromDate:exportStart];
	[self updateExportRowText];
	[[NSUserDefaults standardUserDefaults] setObject:exportStart forKey:kLastExportGoogleFromDate];
}

- (void) exportEndChangeAction
{
	exportEnd = datePicker.date;
	exportEndField.text = [model shortStringFromDate:exportEnd];
	[self updateExportRowText];
	[[NSUserDefaults standardUserDefaults] setObject:exportEnd forKey:kLastExportGoogleToDate];
}

#pragma mark Notification Handlers

- (void) dropboxSessionLinkedAccount:(NSNotification*)notification
{
    [self.tableView reloadData];
}

@end

