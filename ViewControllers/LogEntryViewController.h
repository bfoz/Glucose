#import <UIKit/UIKit.h>

#import "SlidingViewController.h"

@class LogEntry;
@class LogDay;
@class LogModel;
@class NumberFieldCell;

@protocol LogEntryViewDelegate;

@interface LogEntryViewController : SlidingViewController

@property (nonatomic, readonly)	UILabel*    categoryLabel;
@property (nonatomic, readonly)	UILabel*    timestampLabel;

@property (nonatomic, readonly)	NumberFieldCell*	glucoseCell;

@property (nonatomic, assign) id <LogEntryViewDelegate>	delegate;
@property (nonatomic, retain) LogEntry* logEntry;
@property (nonatomic, retain) LogDay*	entrySection;
@property (nonatomic, assign) BOOL	editingNewEntry;
@property (nonatomic, retain) LogModel*	model;

- (id)initWithLogEntry:(LogEntry*)logEntry;

- (void)shaken;

@end

@protocol LogEntryViewDelegate <NSObject>

- (void) logEntryView:(LogEntryViewController*)view didEndEditingEntry:(LogEntry*)entry;

@end
