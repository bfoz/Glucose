#import <UIKit/UIKit.h>
#import "ManagedInsulinDose.h"
#import "NumberField.h"

@protocol DoseFieldCellDelegate;

@interface DoseFieldCell : UITableViewCell <NumberFieldDelegate>
{
    NumberField* doseField;
    UILabel* typeField;
}

@property (nonatomic, weak) id <DoseFieldCellDelegate> delegate;
@property (nonatomic, strong) ManagedInsulinDose*   dose;
@property (nonatomic, readonly) NumberField* doseField;
@property (nonatomic, assign) int   precision;

@end

@protocol DoseFieldCellDelegate <NSObject>

@optional
- (BOOL)doseShouldBeginEditing:(DoseFieldCell*)cell;
- (void)doseDidBeginEditing:(DoseFieldCell*)cell;
- (void)doseDidEndEditing:(DoseFieldCell *)cell;

@end
