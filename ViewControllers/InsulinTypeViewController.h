#import <UIKit/UIKit.h>
#import "TextFieldCell.h"	// Needed for TextFieldCellDelegate

@class LogEntry;
@class LogModel;
@class TextFieldCell;

@protocol InsulinTypeViewControllerDelegate;

@interface InsulinTypeViewController : UITableViewController <TextFieldCellDelegate, UIAlertViewDelegate>
{
    id <InsulinTypeViewControllerDelegate>  __unsafe_unretained delegate;
    LogModel*				    model;

    BOOL			dirty;
    BOOL			multiCheck;
    unsigned	    deleteRowNum;
    enum
    {
	ALERT_REASON_DEFAULT_NEW_ENTRY_TYPE,
	ALERT_REASON_TYPE_NOT_EMPTY
    } alertReason;
}

@property (nonatomic, unsafe_unretained) id <InsulinTypeViewControllerDelegate>   delegate;
@property (nonatomic, strong) LogModel*					model;
@property (nonatomic, assign) BOOL	multiCheck;

- (void) setMultiCheck:(BOOL)e;
- (void) setSelectedInsulinType:(InsulinType*)type;
- (void) setSelectedInsulinTypesWithArray:(NSArray*)types;

@end

@protocol InsulinTypeViewControllerDelegate <NSObject>

@optional
- (void) insulinTypeViewControllerCreateInsulinType;
- (void) insulinTypeViewControllerDidDeleteInsulinType:(InsulinType*)type;
- (void) insulinTypeViewControllerDidEndMultiSelect;
- (BOOL) insulinTypeViewControllerDidSelectInsulinType:(InsulinType*)type;
- (void) insulinTypeViewControllerDidSelectRestoreDefaults;
- (void) insulinTypeViewControllerDidUnselectInsulinType:(InsulinType*)type;

@end
