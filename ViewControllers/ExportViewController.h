#import <UIKit/UIKit.h>

#import "SlidingViewController.h"

@class LogModel;

@interface ExportViewController : SlidingViewController <UITextFieldDelegate>
{
    LogModel*			model;

	NSDate*	exportStart;
	NSDate*	exportEnd;
	BOOL	exportEnabled;
	NSString*	failureTitle;

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

@property (nonatomic, strong) NSMutableDictionary*	keychainData;
@property (nonatomic, strong) NSString*	failureTitle;
@property (nonatomic, strong) LogModel*		    model;

- (void) keychainInit;
- (void) updateExportRowText;

#if !TARGET_IPHONE_SIMULATOR
- (NSMutableDictionary *)dictionaryToSecItemFormat:(NSDictionary *)dictionaryToConvert;
- (NSMutableDictionary *)secItemFormatToDictionary:(NSDictionary *)dictionaryToConvert;
#endif	// !TARGET_IPHONE_SIMULATOR

@end
