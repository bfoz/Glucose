#import <UIKit/UIKit.h>
#import "InsulinDose.h"
#import "NumberField.h"

@protocol DoseFieldCellDelegate;

@interface DoseFieldCell : UITableViewCell <NumberFieldDelegate>
{
    id <DoseFieldCellDelegate> __unsafe_unretained delegate;
    InsulinDose* dose;
    NumberField* doseField;
    UILabel* typeField;
}

@property (nonatomic, unsafe_unretained) id <DoseFieldCellDelegate> delegate;
@property (nonatomic, strong) InsulinDose* dose;
@property (nonatomic, readonly) NumberField* doseField;
@property (nonatomic, assign) int   precision;

@end

@protocol DoseFieldCellDelegate <NSObject>

@optional
- (BOOL)doseShouldBeginEditing:(DoseFieldCell*)cell;
- (void)doseDidBeginEditing:(DoseFieldCell*)cell;
- (void)doseDidEndEditing:(DoseFieldCell *)cell;

@end
