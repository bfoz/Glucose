#import <UIKit/UIKit.h>

#import "LogEntryViewController.h"

@class LogEntry;
@class LogModel;
@class SettingsViewController;

@protocol LogViewDelegate;

@interface LogViewController : UITableViewController <LogEntryViewDelegate>
{
    NSDateFormatter *dateFormatter;
	SettingsViewController*	settingsViewController;
}


- (id)initWithModel:(LogModel*)model delegate:(id<LogViewDelegate>)delegate;

@end

@protocol LogViewDelegate <NSObject>
@end
