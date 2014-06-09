#import <UIKit/UIKit.h>
#import "TextFieldCell.h"	// Needed for TextFieldCellDelegate

@class LogModel;
@class ManagedInsulinType;

@protocol InsulinTypeViewControllerDelegate;

@interface InsulinTypeViewController : UITableViewController <TextFieldCellDelegate, UIAlertViewDelegate>
{
    BOOL			multiCheck;
    enum
    {
	ALERT_REASON_DEFAULT_NEW_ENTRY_TYPE,
	ALERT_REASON_TYPE_NOT_EMPTY
    } alertReason;
}

@property (nonatomic, weak) id<InsulinTypeViewControllerDelegate>   delegate;
@property (nonatomic, strong) LogModel*					model;
@property (nonatomic, assign) BOOL	multiCheck;

- (id) initWithStyle:(UITableViewStyle*)style logModel:(LogModel*)logModel;

- (BOOL) insulinTypeIsSelected:(ManagedInsulinType*)insulinType;

- (void) setMultiCheck:(BOOL)e;
- (void) setSelectedInsulinType:(ManagedInsulinType*)type;
- (void) setSelectedInsulinTypesWithArray:(NSOrderedSet*)types;

@end

@protocol InsulinTypeViewControllerDelegate <NSObject>

@optional
- (BOOL) insulinTypeViewControllerDidSelectInsulinType:(ManagedInsulinType*)type;
- (void) insulinTypeViewControllerDidSelectRestoreDefaults;
- (void) insulinTypeViewControllerDidUnselectInsulinType:(ManagedInsulinType*)type;

@end
