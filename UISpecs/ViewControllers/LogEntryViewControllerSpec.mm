#import "SpecsHelper.h"

#import "DoseFieldCell.h"
#import "LogEntryViewController.h"
#import "LogModel+SpecHelper.h"
#import "ManagedLogDay+App.h"
#import "ManagedLogEntry+App.h"
#import "NumberFieldCell.h"

using namespace Cedar::Matchers;

enum Sections
{
    kSectionGlucose = 0,
    kSectionInsulin,
    kSectionNote,
    NUM_SECTIONS
};

@interface LogEntryViewController (UISpecs)
- (void) categoryViewControllerDidSelectCategory:(id)category;
@end

SPEC_BEGIN(LogEntryViewControllerSpec)

describe(@"LogEntryViewController", ^{
    __block LogEntryViewController* controller;
    __block ManagedLogEntry*	logEntry;

    beforeEach(^{
	LogModel* logModel = [[LogModel alloc] init];
	ManagedLogDay* logDay = [logModel insertManagedLogDay];
	logEntry = [logDay insertManagedLogEntry];

	controller = [[[LogEntryViewController alloc] initWithLogEntry:logEntry] autorelease];
	controller.model = logModel;

	UINavigationController* navigation = [[UINavigationController alloc] initWithRootViewController:controller];
	navigation.topViewController.view should_not be_nil;
    });

    it(@"should not be editing", ^{
	controller.editing should_not be_truthy;
	controller.editingNewEntry should_not be_truthy;
    });

    it(@"should have a right bar button item for editing", ^{
	controller.navigationItem.rightBarButtonItem should_not be_nil;
	controller.navigationItem.rightBarButtonItem should be_same_instance_as(controller.editButtonItem);
    });

    it(@"should have a proper table delegate and dataSource", ^{
	controller.tableView.dataSource should equal(controller);
	controller.tableView.delegate should equal(controller);
    });

    it(@"should have the correct number of sections", ^{
	[controller.tableView numberOfSections] should equal(3);
    });

    it(@"should have 1 row in section 0", ^{
	[controller.tableView numberOfRowsInSection:0] should equal(1);
    });

    xit(@"should have 0 rows in section 1", ^{
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

	xit(@"should have a Back button that says Log", ^{
	    controller.navigationItem.leftBarButtonItem should_not be_nil;
	    controller.navigationItem.leftBarButtonItem.title should equal(@"Log");
	});

	xit(@"should have a Save button", ^{
	    controller.navigationItem.rightBarButtonItem should_not be_nil;
	    controller.navigationItem.rightBarButtonItem.title should equal(@"Save");
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
	});

	it(@"should have a Category label", ^{
	    controller.categoryLabel should_not be_nil;
	    controller.categoryLabel should be_instance_of([UILabel class]);
	    controller.categoryLabel.backgroundColor should equal([UIColor clearColor]);
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

	    it(@"should have a NumberFieldCell for row 2", ^{
		UITableViewCell* cell = [controller.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
		cell should_not be_nil;
		cell should be_instance_of([NumberFieldCell class]);
	    });

	    describe(@"when the Glucose cell is tapped", ^{
		__block NumberFieldCell* glucoseCell;

		beforeEach(^{
		    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:2 inSection:0];
		    glucoseCell = (NumberFieldCell*)[controller.tableView cellForRowAtIndexPath:indexPath];
		    [controller tableView:controller.tableView didSelectRowAtIndexPath:indexPath];
		});

		xit(@"should display the keyboard", ^{
		    glucoseCell.field.isFirstResponder should be_truthy;
		});

		xit(@"should disable the right nav bar button", ^{
		    controller.navigationItem.rightBarButtonItem.enabled should_not be_truthy;
		});

		it(@"should have Cancel and Done buttons above the keyboard", ^{
		    UIToolbar* toolbar = (UIToolbar*)glucoseCell.field.inputAccessoryView;
		    toolbar should_not be_nil;
		    toolbar should be_instance_of([UIToolbar class]);
		    toolbar.items.count should equal(3);
		});

		describe(@"when the Cancel button is tapped", ^{
		    __block UIBarButtonItem* cancelButton;

		    beforeEach(^{
			UIToolbar* toolbar = (UIToolbar*)glucoseCell.field.inputAccessoryView;
			cancelButton = [toolbar.items objectAtIndex:0];
			[cancelButton tap];
		    });

		    it(@"should resign first responder", ^{
			glucoseCell.field.isFirstResponder should_not be_truthy;
		    });

		    it(@"should not update the LogEntry", ^{
		    });

		    it(@"should enable the right nav bar button", ^{
			controller.navigationItem.rightBarButtonItem.enabled should be_truthy;
		    });

		    it(@"should reset the cell label", ^{
		    });
		});

		describe(@"when the Done button is tapped", ^{
		    __block UIBarButtonItem* doneButton;

		    beforeEach(^{

			UIToolbar* toolbar = (UIToolbar*)glucoseCell.field.inputAccessoryView;
			doneButton = [toolbar.items objectAtIndex:2];
			[doneButton tap];
		    });

		    it(@"should resign first responder", ^{
			glucoseCell.field.isFirstResponder should_not be_truthy;
		    });

		    xit(@"should update the LogEntry", ^{
		    });

		    it(@"should enable the right nav bar button", ^{
			controller.navigationItem.rightBarButtonItem.enabled should be_truthy;
		    });
		});
	    });
	});

	describe(@"when the Save button is tapped", ^{
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
	    ManagedInsulinType* insulinType0 = [controller.model insertManagedInsulinType];
	    ManagedInsulinType* insulinType1 = [controller.model insertManagedInsulinType];
	    [controller.model.insulinTypesForNewEntries addObject:insulinType0];
	    [controller.model.insulinTypesForNewEntries addObject:insulinType1];

	    controller.model.insulinTypesForNewEntries.count should_not equal(0);

	    controller.logEntry = [controller.model insertManagedLogEntryWithUndo];

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

	describe(@"Section 0 - Glucose", ^{
	    it(@"should have 3 rows", ^{
		[controller.tableView numberOfRowsInSection:0] should equal(3);
	    });

	    it(@"should show a disclosure indicator on row 0", ^{
		UITableViewCell* cell = [controller.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
		cell.accessoryType should equal(UITableViewCellAccessoryDisclosureIndicator);
		cell.textLabel.text should_not be_nil;
	    });

	    it(@"should show a disclosure indicator on row 1", ^{
		UITableViewCell* cell = [controller.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
		cell.accessoryType should equal(UITableViewCellAccessoryDisclosureIndicator);
	    });

	    it(@"should show a disclosure indicator on row 2", ^{
		UITableViewCell* cell = [controller.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
		cell.accessoryType should equal(UITableViewCellAccessoryDisclosureIndicator);
	    });
	});

	it(@"should have the proper number of rows in section 1", ^{
	    [controller.tableView numberOfRowsInSection:1] should equal(controller.model.insulinTypesForNewEntries.count);
	});

	describe(@"Section 2 - Note", ^{
	    it(@"should have 1 row", ^{
		[controller.tableView numberOfRowsInSection:2] should equal(1);
	    });

	    it(@"should not show a disclosure indicator", ^{
		UITableViewCell* cell = [controller.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
		cell.accessoryType should equal(UITableViewCellAccessoryNone);
	    });
	});

	describe(@"when the Category row is tapped", ^{
	    beforeEach(^{
		[controller tableView:controller.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:kSectionGlucose]];
	    });

	    it(@"should display a modal Category picker", ^{
		controller.modalViewController should_not be_nil;
	    });

	    describe(@"when a Category is picked", ^{
		beforeEach(^{
		    [controller categoryViewControllerDidSelectCategory:nil];
		    [controller viewDidAppear:NO];
		});

		it(@"should dismiss the picker", ^{
		    controller.modalViewController should be_nil;
		});

		xit(@"should make the Glucose row the first responder", ^{
		    NumberFieldCell* cell = (NumberFieldCell*)[controller.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:kSectionGlucose]];
		    cell.field.isFirstResponder should be_truthy;
		});
	    });
	});

	describe(@"when the first Dose row is tapped", ^{
	    beforeEach(^{
		[controller tableView:controller.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kSectionInsulin]];
	    });

	    it(@"should present an insulin type picker", ^{
		controller.modalViewController should_not be_nil;
	    });
	});

	describe(@"when the dose field of the first dose row is tapped", ^{
	    __block DoseFieldCell* cell;

	    beforeEach(^{
		cell = (DoseFieldCell*)[controller.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kSectionInsulin]];
		[cell.doseField becomeFirstResponder];
	    });

	    xit(@"should show the keyboard", ^{
		cell.doseField.isFirstResponder should be_truthy;
	    });

	    it(@"should have a toolbar above the keyboard", ^{
		cell.doseField.inputAccessoryView should_not be_nil;
	    });

	    describe(@"when the dose is changed", ^{
		__block NSNumber* originalDose;
		__block NSString* originalText;

		beforeEach(^{
		    ManagedInsulinDose* insulinDose = [controller.logEntry.insulinDoses objectAtIndex:0];
		    originalDose = insulinDose.dose;

		    originalText = cell.doseField.text;

		    cell.doseField.text = @"1";
		});

		describe(@"when the accessory toolbar Cancel button is tapped", ^{
		    beforeEach(^{

			UIToolbar* toolbar = (UIToolbar*)cell.doseField.inputAccessoryView;
			UIBarButtonItem* cancelButton = [toolbar.items objectAtIndex:0];
			[cancelButton tap];
		    });

		    it(@"should resign first responder", ^{
			cell.doseField.isFirstResponder should_not be_truthy;
		    });

		    it(@"should not update the LogEntry", ^{
			ManagedInsulinDose* insulinDose = [controller.logEntry.insulinDoses objectAtIndex:0];
			[insulinDose.dose isEqualToNumber:originalDose] should be_truthy;
			insulinDose.dose should equal(originalDose);
		    });
		});

		describe(@"when the accessory toolbar Done button is tapped", ^{
		    xit(@"should resign first responder", ^{
			cell.doseField.isFirstResponder should_not be_truthy;
		    });

		    xit(@"should update the LogEntry", ^{
		    });

		    xit(@"should cause the next row to become first responder", ^{
			DoseFieldCell* nextCell = (DoseFieldCell*)[controller.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:kSectionInsulin]];
			nextCell.doseField.isFirstResponder should be_truthy;
		    });
		});
	    });

	    describe(@"when the dose is not changed", ^{
	    });
	});

	describe(@"when the Back button is tapped", ^{
	    __block id mockDelegate;

	    beforeEach(^{
		mockDelegate = [OCMockObject mockForProtocol:@protocol(LogEntryViewDelegate)];
		controller.delegate = mockDelegate;

		[[mockDelegate expect] logEntryViewControllerDidCancelEditing];

//		[controller.navigationItem.leftBarButtonItem tap];
		[controller viewWillDisappear:NO];
	    });

	    it(@"should inform the delegate", ^{
		[mockDelegate verify];
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
});

SPEC_END
