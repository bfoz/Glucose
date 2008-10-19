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
#import "InsulinType.h"

#import "ExportViewController.h"

#import "GDataDocs.h"

#import <Security/Security.h>

#if TARGET_IPHONE_SIMULATOR
#define	kGoogleDocUserName	@"GoogleDocUserName"
#define kGoogleDocPassword	@"GoogleDocPassword"
#define	kSecAttrAccount	@"kSecAttrAccount"
#define	kSecValueData	@"kSecValueData"
#endif // TARGET_IPHONE_SIMULATOR

#define	GENERIC_PASSWORD	0

@implementation ExportViewController

static AppDelegate *appDelegate = nil;
static const uint8_t kKeychainItemIdentifier[]	= "com.google.docs";

@synthesize keychainData;

- (id)initWithStyle:(UITableViewStyle)style
{
	if( self = [super initWithStyle:style] )
	{
		self.title = @"Export";
		if( !appDelegate )
			appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

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

		[self keychainInit];
	}
	return self;
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
	[super dealloc];
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
	return 3;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch( section )
	{
		case 0: return 2;
		case 1: return 2;
		case 2: return 1;
	}
	return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *MyIdentifier = @"MyIdentifier";
	
	UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:MyIdentifier];
	if( !cell )
	{
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:MyIdentifier] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}

	UITextField* f = nil;
	UILabel* label = nil;
	switch( indexPath.section )
	{
		case 0:
			switch( indexPath.row )
			{
				case 0:
					cell.text = @"Username";
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
					cell.text = @"Password";
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
			label = [[UILabel alloc] initWithFrame:CGRectMake(0, kCellTopOffset*2, 100, 20)];
			label.textAlignment = UITextAlignmentRight;
			switch( indexPath.row )
			{
				case 0:
					// The From field defaults to the day after the last export
					//  or the beginning of the LogEntry table if no last export
					cell.text = @"From";
					label.text = [shortDateFormatter stringFromDate:exportStart];
					exportStartField = label;
					exportStartCell = cell;
					break;
				case 1:
					// The To field defaults to Today
					cell.text = @"To";
					label.text = @"Today";
					exportEndField = label;
					exportEndCell = cell;
					break;
			}
			cell.accessoryView = label;
			break;
		}
		case 2:
			switch( indexPath.row )
			{
				case 0:
					cell.text = @"Export";
					cell.textAlignment = UITextAlignmentCenter;
					break;
			}
	}
	return cell;
}

- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)section
{
    switch( section )
	{
        case 0: return @"Google Account Information";
		case 1: return @"Date Range (inclusive)";
    }
    return nil;
}

#pragma mark -
#pragma mark <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if( indexPath.section == 0 )
	{
		switch( indexPath.row )
		{
			case 0: [usernameField becomeFirstResponder]; break;
			case 1: [passwordField becomeFirstResponder]; break;
		}
	}
	else if( indexPath.section == 1 )
	{
		switch( indexPath.row )
		{
			case 0: [self showDatePicker:exportStartCell mode:UIDatePickerModeDate initialDate:exportStart changeAction:@selector(exportStartChangeAction)]; break;
			case 1: [self showDatePicker:exportEndCell mode:UIDatePickerModeDate initialDate:exportEnd changeAction:@selector(exportEndChangeAction)]; break;
		}
	}
	else if( indexPath.section == 2 )
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

		[appDelegate.docService fetchDocsFeedWithURL:[NSURL URLWithString:kGDataGoogleDocsDefaultPrivateFullFeed]
							 delegate:self
					didFinishSelector:@selector(listTicket:finishedWithFeed:)
					  didFailSelector:@selector(listTicket:failedWithError:)];
	}
}

- (CGFloat) tableView:(UITableView*)tableView heightForFooterInSection:(NSInteger)section
{
	return (2 == section) ? 40 : 0;
}

- (UIView*) tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section
{
	if( 2 == section )
	{
		NSUserDefaults *const defaults = [NSUserDefaults standardUserDefaults];
		NSDate *const lastExportStart = [defaults objectForKey:kLastExportGoogleFromDate];
		NSDate *const lastExportEnd = [defaults objectForKey:kLastExportGoogleToDate];
		NSDate *const lastExportedOn = [defaults objectForKey:kLastExportGoogleOnDate];
		
		if( lastExportStart && lastExportEnd && lastExportedOn )
		{
			UILabel* label = [[UILabel alloc] initWithFrame:CGRectZero];
			label.text = [NSString stringWithFormat:@"Last exported from %@ to %@ on %@", [shortDateFormatter stringFromDate:lastExportStart], [shortDateFormatter stringFromDate:lastExportEnd], [shortDateFormatter stringFromDate:lastExportedOn]];
			label.textAlignment = UITextAlignmentCenter;
			label.backgroundColor = [UIColor clearColor];
			label.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];;
			return label;
		}
	}
	return nil;
}

#pragma mark -
#pragma mark Google Doc Export

- (void) cleanupExport
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[progressAlert dismissWithClickedButtonIndex:0 animated:YES];
}

- (void) listTicket:(GDataServiceTicket *)ticket finishedWithFeed:(GDataFeedDocList *)object
{
	GDataEntryDocBase *newEntry = [GDataEntrySpreadsheetDoc documentEntry];
	
	NSString *title = [NSString stringWithFormat:@"Glucose Export from %@ to %@", [shortDateFormatter stringFromDate:exportStart], [shortDateFormatter stringFromDate:exportEnd], nil];
	[newEntry setTitleWithString:title];
	
	NSMutableData *uploadData = [NSMutableData dataWithCapacity:1024];
	NSAssert(uploadData, @"Could not create NSMutableData");

	if( !uploadData )
		[self cleanupExport];

	// Append the header row
	NSString* headerString = @"timestamp,glucose,glucoseUnits,category,dose0,type0,dose1,type1,note\n";
	const char* utfHeader = [headerString UTF8String];
	[uploadData appendBytes:utfHeader length:strlen(utfHeader)];
	
	// Fetch the entries for export
	const char* q = "SELECT timestamp,glucose,glucoseUnits,categoryID,dose0,typeID0,dose1,typeID1,note FROM localLogEntries WHERE date(timestamp,'unixepoch','localtime') >= date(?,'unixepoch','localtime') AND date(timestamp,'unixepoch','localtime') <= date(?,'unixepoch','localtime') ORDER BY timestamp ASC";
	sqlite3_stmt *statement;
	unsigned numRows = 0;
	if( sqlite3_prepare_v2(appDelegate.database, q, -1, &statement, NULL) == SQLITE_OK )
	{
		sqlite3_bind_int(statement, 1, [exportStart timeIntervalSince1970]);
		sqlite3_bind_int(statement, 2, [exportEnd timeIntervalSince1970]);

		NSDateFormatter* f = [[NSDateFormatter alloc] init];
		[f setDateStyle:NSDateFormatterMediumStyle];
		[f setTimeStyle:NSDateFormatterMediumStyle];
		const char* s;
		while( sqlite3_step(statement) == SQLITE_ROW )
		{
			const int count = sqlite3_column_count(statement);
			for( unsigned i=0; i < count; ++i )
			{
				if( i )
					[uploadData appendBytes:"," length:strlen(",")];
				switch( i )
				{
					case 0:	//timestamp
					{
						const int a = sqlite3_column_int(statement, i);
						s = [[f stringFromDate:[NSDate dateWithTimeIntervalSince1970:a]] UTF8String];
					}
					break;
					case 2:	// glucoseUnits
					{
						const int a = sqlite3_column_int(statement, i);
						s = a ? "mmol/L" : "mg/dL";
					}
					break;
					case 3:	// categoryID
					{
						const int a = sqlite3_column_int(statement, i);
						Category* c = [appDelegate findCategoryForID:a];
						s = [c.categoryName UTF8String];
					}
					break;
					case 5:	// typeID0
					case 7:	// typeID1
					{
						const int a = sqlite3_column_int(statement, i);
						InsulinType* t = [appDelegate findInsulinTypeForID:a];
						s = [t.shortName UTF8String];
					}
					break;
					default:
						s = (char*)sqlite3_column_text(statement, i);
				}

				[uploadData appendBytes:"\"" length:strlen("\"")];
				if( s )
					[uploadData appendBytes:s length:strlen(s)];
				[uploadData appendBytes:"\"" length:strlen("\"")];
			}
			[uploadData appendBytes:"\n" length:strlen("\n")];
			++numRows;
		}
		sqlite3_finalize(statement);
		[f release];
	}

	if( !numRows )	// Bail out if no rows
	{
		[self cleanupExport];
		return;
	}

	[newEntry setUploadData:uploadData];
	[newEntry setUploadMIMEType:@"text/csv"];
	[newEntry setUploadSlug:title];
	
	// make service tickets call back into our upload progress selector
	GDataServiceGoogleDocs *const service = appDelegate.docService;
	
	SEL progressSel = @selector(inputStream:hasDeliveredByteCount:ofTotalByteCount:);
	[service setServiceUploadProgressSelector:progressSel];
	
	// insert the entry into the docList feed
	[service fetchDocEntryByInsertingEntry:newEntry
								forFeedURL:[[object postLink] URL]
								  delegate:self
						 didFinishSelector:@selector(uploadFileTicket:finishedWithEntry:)
						   didFailSelector:@selector(uploadFileTicket:failedWithError:)];
	
	[service setServiceUploadProgressSelector:nil];
}

- (void) listTicket:(GDataServiceTicket *)ticket failedWithError:(NSError *)error
{
	NSLog(@"fail: %@", [error localizedDescription]);
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"DocsFeed Failure"
													message:[error localizedDescription]
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles: nil];
	[alert show];
	[alert release];
	[self cleanupExport];
}

// progress callback
- (void)inputStream:(GDataProgressMonitorInputStream *)stream hasDeliveredByteCount:(unsigned long long)numberOfBytesRead  ofTotalByteCount:(unsigned long long)dataLength
{
	progressAlert.message = [NSString stringWithFormat:@"Exported %qu of %qu bytes", numberOfBytesRead, dataLength];
	progressView.progress = ((float)numberOfBytesRead)/dataLength;
}

// upload finished successfully
- (void)uploadFileTicket:(GDataServiceTicket *)ticket finishedWithEntry:(GDataEntryDocBase *)entry
{
	NSUserDefaults *const defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:[NSDate date] forKey:kLastExportGoogleOnDate];
	[defaults setObject:exportStart forKey:kLastExportGoogleFromDate];
	[defaults setObject:exportEnd forKey:kLastExportGoogleToDate];
	// Update the "Last Export On" row
	exportLastField.text = [shortDateFormatter stringFromDate:[NSDate date]];
	[self cleanupExport];
}

// upload failed
- (void)uploadFileTicket:(GDataServiceTicket *)ticket failedWithError:(NSError *)error
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Export Failed"
													message:[error localizedDescription]
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles: nil];
	[alert show];
	[alert release];
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

- (BOOL)textFieldShouldBeginEditing:(UITextField*)field
{
	return [self shouldBeginEditing:[self cellForField:field]];
}

- (void)textFieldDidBeginEditing:(UITextField*)field
{
	[self didBeginEditing:[self cellForField:field] field:field action:[self selectorForField:field]];
}

- (BOOL) textFieldShouldReturn:(UITextField*)textField
{
	[textField resignFirstResponder];
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
}

- (void) exportEndChangeAction
{
	[exportEnd release];
	exportEnd = datePicker.date;
	[exportEnd retain];
	exportEndField.text = [shortDateFormatter stringFromDate:exportEnd];
}

@end

