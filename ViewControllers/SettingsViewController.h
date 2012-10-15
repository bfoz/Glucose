#import <MessageUI/MessageUI.h>
#import <UIKit/UIKit.h>
#import "SlidingViewController.h"

@class CategoryViewController;
@class ExportViewController;
@class InsulinTypeViewController;
@class NumberField;
@class PurgeViewController;
@class LogModel;

@protocol SettingsViewControllerDelegate;

@interface SettingsViewController : SlidingViewController
{
    id<SettingsViewControllerDelegate>    delegate;
    LogModel*		    model;

    CategoryViewController*	categoryViewController;
    InsulinTypeViewController*	defaultInsulinTypeViewController;
    InsulinTypeViewController*	insulinTypeViewController;

    UITableViewCell*	highGlucoseWarningCell;
    UITableViewCell*	lowGlucoseWarningCell;
    NumberField*		highGlucoseWarningField;
    NumberField*		lowGlucoseWarningField;
    NSString*			highGlucoseWarningKey;
    NSString*			lowGlucoseWarningKey;

    ExportViewController*	exportViewController;
}

@property (nonatomic, strong)	id<SettingsViewControllerDelegate>    delegate;
@property (nonatomic, strong) LogModel*				    model;

@end

@protocol SettingsViewControllerDelegate <NSObject>

- (void) settingsViewControllerDidChangeGlucoseUnits;
- (void) settingsViewControllerDidPressBack;

@end
