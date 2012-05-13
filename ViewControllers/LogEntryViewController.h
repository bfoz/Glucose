#import <UIKit/UIKit.h>
#import <sqlite3.h>

#import "DoseFieldCell.h"
#import "InsulinTypeViewController.h"	// For InsulinTypeViewControllerDelegate
#import "NumberFieldCell.h"			// For NumberFieldCellDelegate
#import "TextViewCell.h"
#import "SlidingViewController.h"

@class InsulinTypeViewController;
@class LogEntry;
@class LogDay;
@class LogModel;
@class NumberFieldCell;

@protocol LogEntryViewDelegate;

@interface LogEntryViewController : SlidingViewController <DoseFieldCellDelegate, InsulinTypeViewControllerDelegate, NumberFieldCellDelegate, TextViewCellDelegate>
{
    id <LogEntryViewDelegate>	delegate;
    LogModel*			model;

    LogEntry* entry;
    LogDay*		entrySection;

// Private
    InsulinTypeViewController*	insulinTypeViewController;
    NSDateFormatter*	dateFormatter;
    UITableViewCell*	cellTimestamp;
    BOOL	didSelectRow;
    BOOL	didUndo;
    unsigned	editedIndex;
    BOOL	editingNewEntry;
}

@property (nonatomic, readonly)	UILabel*    categoryLabel;
@property (nonatomic, readonly)	UILabel*    timestampLabel;

@property (nonatomic, readonly)	NumberFieldCell*	glucoseCell;

@property (nonatomic, assign) id <LogEntryViewDelegate>	delegate;
@property (nonatomic, retain) LogEntry* entry;
@property (nonatomic, retain) LogDay* entrySection;
@property (nonatomic, assign) BOOL	editingNewEntry;
@property (nonatomic, retain) LogModel*		    model;

- (void)shaken;

@end

@protocol LogEntryViewDelegate <NSObject>

- (void) logEntryView:(LogEntryViewController*)view didEndEditingEntry:(LogEntry*)entry;

@end
