#import "SpecsHelper.h"

#import "LogModel.h"
#import "CategoryViewController.h"
#import "InsulinTypeViewController.h"
#import "SettingsViewController.h"

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

	mockLogModel = nice_fake_for(LogModel.class);
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
	    mockDelegate = nice_fake_for(@protocol(SettingsViewControllerDelegate));
	    controller.delegate = mockDelegate;

	    [controller.navigationItem.rightBarButtonItem tap];
	});

	it(@"should inform the delegate", ^{
	    mockDelegate should have_received("settingsViewControllerDidPressBack");
	});

	it(@"should flush insulin types for new entries", ^{
	    mockLogModel should have_received("flushInsulinTypesForNewEntries");
	});
    });

    describe(@"Category view controller delegate", ^{
	it(@"should inform the model when the user restores the default categories", ^{
	    [controller categoryViewControllerDidSelectRestoreDefaults];

	    mockLogModel should have_received("restoreBundledCategories");
	    mockLogModel should have_received("save");
	});
    });

    describe(@"Insulin Type view controller delegate", ^{
	it(@"should inform the model when the user restores the default insulin types", ^{
	    [controller insulinTypeViewControllerDidSelectRestoreDefaults];

	    mockLogModel should have_received("restoreBundledInsulinTypes");
	});
    });
});

SPEC_END
