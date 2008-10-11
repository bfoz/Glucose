//
//  ExportViewController.h
//  Glucose
//
//  Created by Brandon Fosdick on 9/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SlidingViewController.h"

@interface ExportViewController : SlidingViewController <UITextFieldDelegate>
{
	NSDate*	exportStart;
	NSDate*	exportEnd;

	UIAlertView*		progressAlert;
	UIProgressView*		progressView;
	UITableViewCell*	usernameCell;
	UITableViewCell*	passwordCell;
	UITableViewCell*	exportStartCell;
	UITableViewCell*	exportEndCell;
	UITextField*		usernameField;
	UITextField*		passwordField;
	UILabel*			exportStartField;
	UILabel*			exportEndField;
	UILabel*			exportLastField;
	UILabel*			spreadsheetLabel;

    NSMutableDictionary*	keychainData;            // The actual Keychain data backing store.
	NSMutableDictionary*	gDocPasswordQuery;
}

@property (nonatomic, retain) NSMutableDictionary *keychainData;

- (void) keychainInit;

#if !TARGET_IPHONE_SIMULATOR
- (NSMutableDictionary *)dictionaryToSecItemFormat:(NSDictionary *)dictionaryToConvert;
- (NSMutableDictionary *)secItemFormatToDictionary:(NSDictionary *)dictionaryToConvert;
#endif	// !TARGET_IPHONE_SIMULATOR

@end
