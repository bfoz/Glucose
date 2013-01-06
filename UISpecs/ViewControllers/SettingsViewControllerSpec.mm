#import "SpecHelper.h"
#import "OCMock.h"

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
    __block id mockLogModel;

    beforeEach(^{
	controller = [[SettingsViewController alloc] init];

	mockLogModel = [OCMockObject mockForClass:[LogModel class]];
	controller.model = mockLogModel;

	controller.view should_not be_nil;
    });

    describe(@"Category view controller delegate", ^{
	it(@"should inform the model when the user restores the default categories", ^{
	    [[mockLogModel expect] restoreBundledCategories];
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
