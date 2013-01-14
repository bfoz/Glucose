#import <UIKit/UIKit.h>

@class ManagedLogEntry;
@class LogDay;
@class LogModel;
@class NumberFieldCell;

@protocol LogEntryViewDelegate;

@interface LogEntryViewController : UITableViewController

@property (nonatomic, strong, readonly)	UILabel*    categoryLabel;
@property (nonatomic, strong, readonly)	UILabel*    timestampLabel;

@property (nonatomic, unsafe_unretained) id <LogEntryViewDelegate>	delegate;
@property (nonatomic, strong) ManagedLogEntry*	logEntry;
@property (nonatomic, assign) BOOL	editingNewEntry;
@property (nonatomic, strong) LogModel*	model;

- (id)initWithLogEntry:(ManagedLogEntry*)logEntry;

@end

@protocol LogEntryViewDelegate <NSObject>

- (void) logEntryView:(LogEntryViewController*)view didEndEditingEntry:(ManagedLogEntry*)entry;
- (void) logEntryViewControllerDidCancelEditing;

@end
