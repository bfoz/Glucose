#import <UIKit/UIKit.h>

#import "SlidingViewController.h"

@class LogEntry;
@class LogDay;
@class LogModel;
@class NumberFieldCell;

@protocol LogEntryViewDelegate;

@interface LogEntryViewController : SlidingViewController

@property (unsafe_unretained, nonatomic, readonly)	UILabel*    categoryLabel;
@property (unsafe_unretained, nonatomic, readonly)	UILabel*    timestampLabel;

@property (unsafe_unretained, nonatomic, readonly)	NumberFieldCell*	glucoseCell;

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
