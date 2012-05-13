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

@interface LogEntry : NSObject

@end

SPEC_BEGIN(LogEntryViewControllerSpec)

describe(@"LogEntryViewController", ^{
    __block LogEntryViewController *controller;
    __block id mockLogEntry;

    beforeEach(^{
	mockLogEntry = [OCMockObject niceMockForClass:[LogEntry class]];
	controller = [[[LogEntryViewController alloc] initWithLogEntry:mockLogEntry] autorelease];
	controller.view should_not be_nil;
    });

    it(@"should have a right bar button item for editing", ^{
	controller.navigationItem.rightBarButtonItem should_not be_nil;
	controller.navigationItem.rightBarButtonItem should be_same_instance_as(controller.editButtonItem);
    });

    it(@"should have a proper table delegate and dataSource", ^{
	controller.tableView.dataSource should equal(controller);
	controller.tableView.delegate should equal(controller);
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

	    controller.tableView.visibleCells should_not be_nil;
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

	it(@"should have 0 rows in section 1", ^{
	    [controller.tableView numberOfRowsInSection:1] should equal(0);
	});

	it(@"should have 1 row in section 2", ^{
	    [controller.tableView numberOfRowsInSection:2] should equal(1);
	});

	it(@"should have a Timestamp label", ^{
	    controller.timestampLabel should_not be_nil;
	    controller.timestampLabel should be_instance_of([UILabel class]);
	    controller.timestampLabel.backgroundColor should equal([UIColor clearColor]);
	});

	it(@"should have a Category label", ^{
	    controller.categoryLabel should_not be_nil;
	    controller.categoryLabel should be_instance_of([UILabel class]);
	    controller.categoryLabel.backgroundColor should equal([UIColor clearColor]);
	});

	it(@"should have a Glucose cell", ^{
	    controller.glucoseCell should_not be_nil;
	    controller.glucoseCell should be_instance_of([NumberFieldCell class]);
	});

	describe(@"Section 0", ^{
	    it(@"should have 3 rows", ^{
		[controller.tableView numberOfRowsInSection:0] should equal(3);
	    });

	    describe(@"row 0", ^{
		it(@"should be a normal cell", ^{
		    UITableViewCell* cell = [controller.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
		    cell should_not be_nil;
		    cell should be_instance_of([UITableViewCell class]);
		});
	    });
	});

	describe(@"when the Done button is tapped", ^{
	    __block id mockDelegate;

	    beforeEach(^{
		mockDelegate = [OCMockObject mockForProtocol:@protocol(LogEntryViewDelegate)];
		controller.delegate = mockDelegate;
		[[mockDelegate expect] logEntryView:controller didEndEditingEntry:OCMOCK_ANY];

		[controller.navigationItem.rightBarButtonItem tap];
	    });

	    it(@"should cancel Edit mode", ^{
		controller.editing should_not be_truthy;
	    });

	    it(@"should update the title", ^{
		controller.title should equal(@"Details");
	    });

	    it(@"should inform the delegate", ^{
		[mockDelegate verify];
	    });
	});
    });

    describe(@"when initialized with a new entry", ^{
	beforeEach(^{
	    controller.editingNewEntry = YES;
	    [controller setEditing:YES animated:NO];
	});

	it(@"should be in edit mode", ^{
	    controller.editing should be_truthy;
	});

	it(@"should update the title", ^{
	    controller.title should equal(@"New Entry");
	});

	it(@"should have a Done button", ^{
	    controller.navigationItem.rightBarButtonItem.title should equal(@"Done");
	});

	it(@"should have 3 sections", ^{
	    [controller.tableView numberOfSections] should equal(3);
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
	    __block id mockDelegate;

	    beforeEach(^{
		mockDelegate = [OCMockObject mockForProtocol:@protocol(LogEntryViewDelegate)];
		controller.delegate = mockDelegate;
		[[mockDelegate expect] logEntryView:controller didEndEditingEntry:OCMOCK_ANY];

		[controller.navigationItem.rightBarButtonItem tap];
	    });

	    it(@"should cancel Edit mode", ^{
		controller.editing should_not be_truthy;
	    });

	    it(@"should update the title", ^{
		controller.title should equal(@"Details");
	    });

	    it(@"should inform the delegate", ^{
		[mockDelegate verify];
	    });
	});
    });
});

SPEC_END
