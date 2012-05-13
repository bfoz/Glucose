#import "SpecHelper.h"
#import "OCMock.h"

#import "LogEntryViewController.h"

using namespace Cedar::Matchers;

@implementation UIControl (SpecHelper)

- (void)tap
{
    [self sendActionsForControlEvents:UIControlEventTouchUpInside];
}

@end

@implementation UIBarButtonItem (SpecHelper)

- (void)tap
{
    if( [self.customView isKindOfClass:[UIButton class]] )
        [(UIButton*)self.customView tap];
    else
        [self.target performSelector:self.action];
}

@end

SPEC_BEGIN(LogEntryViewControllerSpec)

describe(@"LogEntryViewController", ^{
    __block LogEntryViewController *controller;

    beforeEach(^{
	controller = [[[LogEntryViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
	controller.view should_not be_nil;
    });
    
    it(@"should have a right bar button item for editing", ^{
	controller.navigationItem.rightBarButtonItem should_not be_nil;
	controller.navigationItem.rightBarButtonItem should be_same_instance_as(controller.editButtonItem);
    });
    
    it(@"should have 1 sections", ^{
	[controller.tableView numberOfSections] should equal(1);
    });

    it(@"should have 1 row in section 0", ^{
	[controller.tableView numberOfRowsInSection:0] should equal(1);
    });
    
    xit(@"should have X rows in section 1", ^{
	[controller.tableView numberOfRowsInSection:1] should equal(0);
    });
    
    xit(@"should have X rows in section 2", ^{
	[controller.tableView numberOfRowsInSection:2] should equal(1);
    });

    describe(@"when the Edit button is tapped", ^{
	beforeEach(^{
	    [controller.navigationItem.rightBarButtonItem tap];
	});
	
	it(@"should be in edit mode", ^{
	    controller.editing should be_truthy;
	});

	it(@"should update the title", ^{
	    controller.title should equal(@"Edit Entry");
	});
	
	it(@"should have 3 sections", ^{
	    [controller.tableView numberOfSections] should equal(3);
	});
	
	it(@"should have a Done button", ^{
	    controller.navigationItem.rightBarButtonItem should_not be_nil;
	    controller.navigationItem.rightBarButtonItem.title should equal(@"Done");
	});
	
	it(@"should have 3 rows in section 0", ^{
	    [controller.tableView numberOfRowsInSection:0] should equal(3);
	});
	
	it(@"should have 0 rows in section 1", ^{
	    [controller.tableView numberOfRowsInSection:1] should equal(0);
	});
	
	it(@"should have 1 row in section 2", ^{
	    [controller.tableView numberOfRowsInSection:2] should equal(1);
	});

	describe(@"when the Done button is tapped", ^{
	    beforeEach(^{
		[controller.navigationItem.rightBarButtonItem tap];
	    });
	    
	    it(@"should cancel Edit mode", ^{
		controller.editing should_not be_truthy;
	    });
	    
	    it(@"should update the title", ^{
		controller.title should equal(@"Details");
	    });
	});
    });
});

SPEC_END
