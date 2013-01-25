#import "SpecsHelper.h"

#import "CategoryViewController.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(CategoryViewControllerSpec)

describe(@"CategoryViewController", ^{
    __block CategoryViewController* controller;

    beforeEach(^{
	controller = [[CategoryViewController alloc] init];
	controller.view should_not be_nil;
    });

    it(@"should set the title", ^{
	controller.title should equal(@"Categories");
    });

    it(@"should allow selection during editing", ^{
	controller.tableView.allowsSelectionDuringEditing should be_truthy;
    });

    it(@"should not be in edit mode", ^{
	controller.editing should_not be_truthy;
    });

    describe(@"when in edit mode", ^{
	beforeEach(^{
	    [controller setEditing:YES animated:NO];
	});

	it(@"should be in edit mode", ^{
	    controller.editing should be_truthy;
	});

	it(@"should have an Add button", ^{
	    controller.navigationItem.rightBarButtonItem should_not be_nil;
	});
    });
});

SPEC_END
