//
//  ExportViewController.h
//  Glucose
//
//  Created by Brandon Fosdick on 9/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SlidingViewController.h"

@class GDataEntryDocBase;
@class GDataFeedACL;
@class GDataServiceTicket;

@interface ExportViewController : SlidingViewController <UITextFieldDelegate>
{
	NSDate*	exportStart;
	NSDate*	exportEnd;
	BOOL	exportEnabled;

	UIAlertView*		progressAlert;
	UIProgressView*		progressView;
	UITableViewCell*	usernameCell;
	UITableViewCell*	passwordCell;
	UITableViewCell*	exportCell;
	UITableViewCell*	exportStartCell;
	UITableViewCell*	exportEndCell;
	UITextField*		usernameField;
	UITextField*		passwordField;
	UILabel*			exportStartField;
	UILabel*			exportEndField;
	UILabel*			exportLastField;
	UISwitch*			shareSwitch;
	UILabel*			spreadsheetLabel;

    NSMutableDictionary*	keychainData;            // The actual Keychain data backing store.
	NSMutableDictionary*	gDocPasswordQuery;

	NSURL*				aclURL;
	NSMutableArray*		contacts;
	NSEnumerator*		contactsEnumerator;
	BOOL				showingContacts;
}

@property (nonatomic, retain) NSMutableDictionary *keychainData;

- (void) addACLTicket:(GDataServiceTicket *)ticket finishedWithEntry:(GDataFeedACL*)object;
- (void) keychainInit;
- (void) updateExportRowText;

#if !TARGET_IPHONE_SIMULATOR
- (NSMutableDictionary *)dictionaryToSecItemFormat:(NSDictionary *)dictionaryToConvert;
- (NSMutableDictionary *)secItemFormatToDictionary:(NSDictionary *)dictionaryToConvert;
#endif	// !TARGET_IPHONE_SIMULATOR

@end
