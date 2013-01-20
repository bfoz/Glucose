#import <UIKit/UIKit.h>
#import "TextFieldCell.h"	// Needed for TextFieldCellDelegate

@class LogEntry;
@class LogModel;
@class ManagedInsulinType;
@class TextFieldCell;

@protocol InsulinTypeViewControllerDelegate;

@interface InsulinTypeViewController : UITableViewController <TextFieldCellDelegate, UIAlertViewDelegate>
{
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

@property (nonatomic, weak) id<InsulinTypeViewControllerDelegate>   delegate;
@property (nonatomic, strong) LogModel*					model;
@property (nonatomic, assign) BOOL	multiCheck;

- (void) setMultiCheck:(BOOL)e;
- (void) setSelectedInsulinType:(ManagedInsulinType*)type;
- (void) setSelectedInsulinTypesWithArray:(NSOrderedSet*)types;

@end

@protocol InsulinTypeViewControllerDelegate <NSObject>

@optional
- (void) insulinTypeViewControllerCreateInsulinType;
- (void) insulinTypeViewControllerDidDeleteInsulinType:(ManagedInsulinType*)type;
- (void) insulinTypeViewControllerDidEndMultiSelect;
- (BOOL) insulinTypeViewControllerDidSelectInsulinType:(ManagedInsulinType*)type;
- (void) insulinTypeViewControllerDidSelectRestoreDefaults;
- (void) insulinTypeViewControllerDidUnselectInsulinType:(ManagedInsulinType*)type;

@end
