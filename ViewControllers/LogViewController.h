#import <UIKit/UIKit.h>

#import "LogEntryViewController.h"

@class LogEntry;
@class LogModel;
@class SettingsViewController;
@protocol LogViewDelegate;

@interface LogViewController : UITableViewController <LogEntryViewDelegate>
{
    NSDateFormatter *dateFormatter;
//	unsigned	inspectingSectionID;
//	NSMutableDictionary*	inspectingSection;
	SettingsViewController*	settingsViewController;
}


- (id)initWithModel:(LogModel*)model delegate:(id<LogViewDelegate>)delegate;

- (void) inspectLogEntry:(LogEntry*)entry inSection:(LogDay*)section;
- (void) inspectLogEntry:(LogEntry*)entry inSection:(LogDay*)section setEditing:(BOOL)e isNew:(BOOL)n;
- (void) inspectNewLogEntry:(LogEntry*)entry;

@end

@protocol LogViewDelegate <NSObject>
@end
