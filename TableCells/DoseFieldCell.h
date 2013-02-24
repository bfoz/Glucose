#import <UIKit/UIKit.h>
#import "ManagedInsulinDose.h"
#import "NumberField.h"

@protocol DoseFieldCellDelegate;

@interface DoseFieldCell : UITableViewCell <NumberFieldDelegate>

@property (nonatomic, weak) id <DoseFieldCellDelegate> delegate;
@property (nonatomic, strong) ManagedInsulinDose*   dose;
@property (nonatomic, strong) ManagedInsulinType*   insulinType;
@property (nonatomic, readonly) NumberField*	doseField;
@property (nonatomic, readonly) UILabel*	typeField;
@property (nonatomic, assign) int   precision;

+ (DoseFieldCell*) cellForInsulinDose:(ManagedInsulinDose*)insulinDose
			accessoryView:(UIView*)accessoryView
			     delegate:(id<DoseFieldCellDelegate>)delegate
			    precision:(unsigned)precision
			    tableView:(UITableView*)tableView;

+ (DoseFieldCell*) cellForInsulinType:(ManagedInsulinType*)insulinType
			accessoryView:(UIView*)accessoryView
			     delegate:(id<DoseFieldCellDelegate>)delegate
			    precision:(unsigned)precision
			    tableView:(UITableView*)tableView;

@end

@protocol DoseFieldCellDelegate <NSObject>

@optional
- (BOOL)doseShouldBeginEditing:(DoseFieldCell*)cell;
- (void)doseDidBeginEditing:(DoseFieldCell*)cell;
- (void)doseDidEndEditing:(DoseFieldCell *)cell;

@end
