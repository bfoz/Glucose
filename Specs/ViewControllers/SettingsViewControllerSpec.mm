#import "SpecsHelper.h"

#import "LogModel.h"
#import "CategoryViewController.h"
#import "InsulinTypeViewController.h"
#import "SettingsViewController.h"

using namespace Cedar::Matchers;

@interface SettingsViewController () <CategoryViewControllerDelegate, InsulinTypeViewControllerDelegate>
@end

SPEC_BEGIN(SettingsViewControllerSpec)

describe(@"SettingsViewController", ^{
    __block SettingsViewController* controller;
    __block UINavigationController* navigationController;
    __block id mockLogModel;

    beforeEach(^{
	controller = [[[SettingsViewController alloc] init] autorelease];
	navigationController = [[[UINavigationController alloc] initWithRootViewController:controller] autorelease];
	navigationController.topViewController should be_same_instance_as(controller);

	mockLogModel = [OCMockObject mockForClass:[LogModel class]];
	controller.model = mockLogModel;

	controller.view should_not be_nil;
    });

    it(@"should set the title", ^{
	controller.title should equal(@"Settings");
    });

    it(@"should hide the stock Back button", ^{
	controller.navigationItem.hidesBackButton should be_truthy;
    });

    describe(@"when the Done button is tapped", ^{
	__block id mockDelegate;

	beforeEach(^{
	    mockDelegate = [OCMockObject mockForProtocol:@protocol(SettingsViewControllerDelegate)];
	    controller.delegate = mockDelegate;

	    [[mockDelegate expect] settingsViewControllerDidPressBack];
	    [[mockLogModel expect] flushInsulinTypesForNewEntries];
	    [controller.navigationItem.rightBarButtonItem tap];
	});

	it(@"should inform the delegate", ^{
	    [mockDelegate verify];
	});

	it(@"should flush insulin types for new entries", ^{
	    [mockLogModel verify];
	});
    });

    describe(@"Category view controller delegate", ^{
	it(@"should inform the model when the user restores the default categories", ^{
	    [[mockLogModel expect] restoreBundledCategories];
	    [[mockLogModel expect] save];
	    [controller categoryViewControllerDidSelectRestoreDefaults];
	    [mockLogModel verify];
	});
    });

    describe(@"Insulin Type view controller delegate", ^{
	it(@"should inform the model when the user restores the default insulin types", ^{
	    [[mockLogModel expect] restoreBundledInsulinTypes];
	    [controller insulinTypeViewControllerDidSelectRestoreDefaults];
	    [mockLogModel verify];
	});
    });
});

SPEC_END
