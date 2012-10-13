#import <UIKit/UIKit.h>

#import "SlidingViewController.h"

@class LogEntry;
@class LogDay;
@class LogModel;
@class NumberFieldCell;

@protocol LogEntryViewDelegate;

@interface LogEntryViewController : SlidingViewController

@property (nonatomic, strong, readonly)	UILabel*    categoryLabel;
@property (nonatomic, strong, readonly)	UILabel*    timestampLabel;

@property (nonatomic, unsafe_unretained) id <LogEntryViewDelegate>	delegate;
@property (nonatomic, strong) LogEntry* logEntry;
@property (nonatomic, strong) LogDay*	entrySection;
@property (nonatomic, assign) BOOL	editingNewEntry;
@property (nonatomic, strong) LogModel*	model;

- (id)initWithLogEntry:(LogEntry*)logEntry;

- (void)shaken;

@end

@protocol LogEntryViewDelegate <NSObject>

- (void) logEntryView:(LogEntryViewController*)view didEndEditingEntry:(LogEntry*)entry;

@end
