#import <MessageUI/MessageUI.h>
#import <UIKit/UIKit.h>

@class CategoryViewController;
@class InsulinTypeViewController;
@class NumberField;
@class PurgeViewController;
@class LogModel;

@protocol SettingsViewControllerDelegate;

@interface SettingsViewController : UITableViewController
{
    LogModel*		    model;

    NumberField*		highGlucoseWarningField;
    NumberField*		lowGlucoseWarningField;
}

@property (nonatomic, weak)	id<SettingsViewControllerDelegate>    delegate;
@property (nonatomic, strong) LogModel*				    model;

@end

@protocol SettingsViewControllerDelegate <NSObject>

- (void) settingsViewControllerDidChangeGlucoseUnits;
- (void) settingsViewControllerDidPressBack;

@end
