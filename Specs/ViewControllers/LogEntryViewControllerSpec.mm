#import "SpecsHelper.h"

#import "ManagedCategory.h"
#import "ManagedLogDay+App.h"
#import "ManagedLogEntry+App.h"

#import "DateField.h"
#import "DoseFieldCell.h"
#import "InsulinTypeViewController.h"
#import "LogEntryViewController.h"
#import "LogModel+SpecHelper.h"
#import "NumberFieldCell.h"
#import "TextViewCell.h"

using namespace Cedar::Matchers;

enum Sections
{
    kSectionGlucose = 0,
    kSectionInsulin,
    kSectionNote,
    NUM_SECTIONS
};

@interface LogEntryViewController (UISpecs)
@property (nonatomic, strong) UILabel*	    categoryLabel;
@property (nonatomic, strong) DateField*    timestampField;
@property (nonatomic, strong) UILabel*	    timestampLabel;

- (void) categoryViewControllerDidSelectCategory:(id)category;
@end

SPEC_BEGIN(LogEntryViewControllerSpec)

describe(@"LogEntryViewController", ^{
    __block LogEntryViewController* controller;
    __block ManagedLogEntry*	logEntry;
    __block LogModel*	logModel;

    beforeEach(^{
	logModel = [[[LogModel alloc] init] autorelease];
    });

    describe(@"when displaying an existing log entry", ^{
	beforeEach(^{
	    logEntry = [logModel insertManagedLogEntry];

	    controller = [[[LogEntryViewController alloc] initWithLogEntry:logEntry] autorelease];
	    controller.model = logModel;

	    UINavigationController* navigation = [[UINavigationController alloc] initWithRootViewController:[[UIViewController alloc] init]];
	    [navigation pushViewController:controller animated:NO];
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

	it(@"should have 0 rows in section 1", ^{
	    [controller.tableView numberOfRowsInSection:1] should equal([logModel.insulinTypesForNewEntries count]);
	});

	describe(@"when the log entry has no insulin doses", ^{
	    beforeEach(^{
		logEntry.insulinDoses.count should equal(0);
	    });

	    it(@"should not show any insulin dose rows", ^{
		[controller.tableView numberOfRowsInSection:kSectionInsulin] should equal(0);
	    });

	    it(@"should not have a section header", ^{
		[controller tableView:nil titleForHeaderInSection:kSectionInsulin] should be_nil;
	    });
	});

	describe(@"when the log entry has 1 insulin dose", ^{
	    beforeEach(^{
		ManagedInsulinType* insulinType0 = [controller.model insertManagedInsulinTypeShortName:@"InsulinType0"];
		ManagedInsulinDose* insulinDose = [logEntry addDoseWithType:insulinType0];
		insulinDose.dose = @1;
	    });

	    it(@"should show a single dose row", ^{
		[controller.tableView numberOfRowsInSection:kSectionInsulin] should equal(1);
	    });

	    it(@"should not have a section header", ^{
		[controller tableView:nil titleForHeaderInSection:kSectionInsulin] should be_nil;
	    });
	});

	describe(@"when the log entry has 2 insulin doses", ^{
	    beforeEach(^{
		ManagedInsulinType* insulinType0 = [controller.model insertManagedInsulinTypeShortName:@"InsulinType0"];
		ManagedInsulinType* insulinType1 = [controller.model insertManagedInsulinTypeShortName:@"InsulinType1"];
		ManagedInsulinDose* insulinDose = [logEntry addDoseWithType:insulinType0];
		insulinDose.dose = @1;
		insulinDose = [logEntry addDoseWithType:insulinType1];
		insulinDose.dose = @2;
	    });

	    it(@"should show two dose rows", ^{
		[controller.tableView numberOfRowsInSection:kSectionInsulin] should equal(2);
	    });

	    it(@"should not have a section header", ^{
		[controller tableView:nil titleForHeaderInSection:kSectionInsulin] should be_nil;
	    });
	});

	describe(@"when the log entry has a note", ^{
	    beforeEach(^{
		logEntry.note = @"This is a note";
	    });

	    it(@"should display a header for the Note section", ^{
		[controller tableView:nil titleForHeaderInSection:kSectionNote] should equal(@"Note");
	    });

	    it(@"should have 1 row in the Note section", ^{
		[controller.tableView numberOfRowsInSection:kSectionNote] should equal(1);
	    });

	    it(@"should have the correct text", ^{
		UITableViewCell* cell = [controller tableView:controller.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kSectionNote]];
		cell.textLabel.text should equal(@"This is a note");
	    });
	});

	describe(@"when the log entry does not have a note", ^{
	    beforeEach(^{
		logEntry.note = nil;
	    });

	    it(@"should not display a header for the Note section", ^{
		[controller tableView:nil titleForHeaderInSection:kSectionNote] should be_nil;
	    });

	    it(@"should not have any rows in the Note section", ^{
		[controller.tableView numberOfRowsInSection:kSectionNote] should equal(0);
	    });
	});
    });

    describe(@"when the Edit button is tapped", ^{
	beforeEach(^{
	    logEntry = [logModel insertManagedLogEntry];
	    logEntry.glucose = @1;
	    [logModel save];

	    controller = [[[LogEntryViewController alloc] initWithLogEntry:logEntry] autorelease];
	    controller.model = logModel;

	    UIViewController* rootViewController = [[[UIViewController alloc] init] autorelease];
	    rootViewController.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Log" style:UIBarButtonItemStylePlain target:nil action:nil];

	    UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:rootViewController];
	    [navigationController pushViewController:controller animated:NO];
	    controller.view should_not be_nil;
	    navigationController.topViewController should be_same_instance_as(controller);

	    controller.tableView.visibleCells should_not be_nil;

	    UIWindow* window = [[UIWindow alloc] init];
	    window.rootViewController = navigationController;
	    [window makeKeyAndVisible];

	    [controller.navigationItem.rightBarButtonItem tap];
	});

	it(@"should be in edit mode", ^{
	    controller.editing should be_truthy;
	});

	it(@"should have a Cancel button", ^{
	    controller.navigationItem.leftBarButtonItem should_not be_nil;
	    controller.navigationItem.leftBarButtonItem should be_instance_of([[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:nil action:nil] class]);
	});

	it(@"should update the title", ^{
	    controller.title should equal(@"Edit Entry");
	});

	it(@"should have 3 sections", ^{
	    [controller.tableView numberOfSections] should equal(3);
	});

	it(@"should have a Save button", ^{
	    controller.navigationItem.rightBarButtonItem should_not be_nil;
	    controller.navigationItem.rightBarButtonItem.title should equal(@"Done");
	});

	it(@"should have 0 rows in section 1", ^{
	    [controller.tableView numberOfRowsInSection:1] should equal(0);
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

		it(@"should display the keyboard", ^{
		    glucoseCell.field.isFirstResponder should be_truthy;
		});

		it(@"should disable the right nav bar button", ^{
		    controller.navigationItem.rightBarButtonItem.enabled should_not be_truthy;
		});

		it(@"should have Cancel and Done buttons above the keyboard", ^{
		    UIToolbar* toolbar = (UIToolbar*)glucoseCell.field.inputAccessoryView;
		    toolbar should_not be_nil;
		    toolbar should be_instance_of([UIToolbar class]);
		    toolbar.items.count should equal(3);
		});

		describe(@"when the Glucose value is changed", ^{
		    beforeEach(^{
			glucoseCell.number = @42;
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

			it(@"should restore the previous value", ^{
			    glucoseCell.number should_not equal(@42);
			});

			it(@"should enable the right nav bar button", ^{
			    controller.navigationItem.rightBarButtonItem.enabled should be_truthy;
			});
		    });

		    describe(@"when the Done button is tapped", ^{
			beforeEach(^{
			    UIToolbar* toolbar = (UIToolbar*)glucoseCell.field.inputAccessoryView;
			    UIBarButtonItem* doneButton = [toolbar.items objectAtIndex:2];
			    [doneButton tap];
			});

			it(@"should resign first responder", ^{
			    glucoseCell.field.isFirstResponder should_not be_truthy;
			});

			it(@"should accept the new value", ^{
			    glucoseCell.number should equal(@42);
			});

			it(@"should enable the right nav bar button", ^{
			    controller.navigationItem.rightBarButtonItem.enabled should be_truthy;
			});
		    });
		});
	    });
	});

	describe(@"Section 2 - Note", ^{
	    it(@"should have 1 row", ^{
		[controller.tableView numberOfRowsInSection:kSectionNote] should equal(1);
	    });

	    it(@"should have a section header", ^{
		[controller tableView:nil titleForHeaderInSection:kSectionNote] should equal(@"Note");
	    });
	});

	describe(@"when the Save button is tapped", ^{
	    beforeEach(^{
		[controller.navigationItem.rightBarButtonItem tap];
	    });

	    it(@"should cancel Edit mode", ^{
		controller.editing should_not be_truthy;
	    });

	    it(@"should update the left bar button item", ^{
		controller.navigationItem.leftBarButtonItem.title should_not equal(@"Cancel");
	    });

	    it(@"should update the title", ^{
		controller.title should equal(@"Details");
	    });

	    it(@"should update the model", ^{
		[controller.logEntry hasChanges] should_not be_truthy;
	    });
	});
    });

    describe(@"when initialized for a new entry", ^{
	beforeEach(^{
	    ManagedInsulinType* insulinType0 = [logModel insertManagedInsulinTypeShortName:@"InsulinType0"];
	    ManagedInsulinType* insulinType1 = [logModel insertManagedInsulinTypeShortName:@"InsulinType1"];
	    [logModel.insulinTypesForNewEntries addObject:insulinType0];
	    [logModel.insulinTypesForNewEntries addObject:insulinType1];

	    logModel.insulinTypesForNewEntries.count should equal(2);

	    UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:[[UIViewController alloc] init]];

	    controller = [[[LogEntryViewController alloc] initWithLogModel:logModel] autorelease];

	    [navigationController pushViewController:controller animated:NO];

	    UIWindow* window = [[UIWindow alloc] init];
	    window.rootViewController = navigationController;
	    [window makeKeyAndVisible];
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

	    it(@"should show the correct placeholder category text", ^{
		UITableViewCell* cell = [controller.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
		cell.textLabel.text = @"Category";
		cell.textLabel.textColor = [UIColor lightGrayColor];
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

	    it(@"should have the correct section title", ^{
		[controller tableView:nil titleForHeaderInSection:kSectionNote] should equal(@"Note");
	    });
	});

	describe(@"when the timestamp row is tapped", ^{
	    beforeEach(^{
		[controller tableView:nil didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kSectionGlucose]];
	    });

	    it(@"should become first responder", ^{
		[controller.timestampField isFirstResponder] should be_truthy;
	    });

	    it(@"should disable the right nav bar button", ^{
		controller.navigationItem.rightBarButtonItem.enabled should_not be_truthy;
	    });

	    describe(@"when the date is changed", ^{
		__block NSDate* newDate;
		__block NSDate* originalDate;

		beforeEach(^{
		    newDate = [NSDate dateWithTimeIntervalSince1970:1000];
		    originalDate = controller.timestampField.date;

		    controller.timestampField.date = newDate;
		});

		describe(@"when the date picker Cancel button is tapped", ^{
		    beforeEach(^{
			UIToolbar* toolbar = controller.timestampField.toolbar;
			UIBarButtonItem* doneButton = [toolbar.items objectAtIndex:0];
			[doneButton tap];
		    });

		    it(@"should resign first responder", ^{
			[controller.timestampField isFirstResponder] should_not be_truthy;
		    });

		    it(@"should enable the right nav bar button", ^{
			controller.navigationItem.rightBarButtonItem.enabled should be_truthy;
		    });

		    it(@"should restore the original date", ^{
			controller.timestampField.date = originalDate;
		    });
		});

		describe(@"when the date picker Done button is tapped", ^{
		    beforeEach(^{
			UIToolbar* toolbar = controller.timestampField.toolbar;
			UIBarButtonItem* doneButton = [toolbar.items objectAtIndex:2];
			[doneButton tap];
		    });

		    it(@"should resign first responder", ^{
			[controller.timestampField isFirstResponder] should_not be_truthy;
		    });

		    it(@"should enable the right nav bar button", ^{
			controller.navigationItem.rightBarButtonItem.enabled should be_truthy;
		    });

		    it(@"should accept the new date", ^{
			controller.timestampField.date should equal(newDate);
			controller.timestampLabel.text should_not be_nil;
		    });
		});
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
		__block ManagedCategory* category;

		beforeEach(^{
		    category = [[logModel categories] lastObject];
		    category should_not be_nil;
		    [controller categoryViewControllerDidSelectCategory:category];
		    [controller viewDidAppear:NO];
		});

		it(@"should dismiss the picker", ^{
		    controller.modalViewController should be_nil;
		});

		it(@"should update the Category label", ^{
		    controller.categoryLabel.text should equal(category.name);
		    controller.categoryLabel.textColor should_not equal([UIColor lightGrayColor]);
		});

		it(@"should make the Glucose row the first responder", ^{
		    NumberFieldCell* cell = (NumberFieldCell*)[controller.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:kSectionGlucose]];
		    cell.field.isFirstResponder should be_truthy;
		});
	    });
	});

	describe(@"when the first Dose row is tapped", ^{
	    beforeEach(^{
		logModel.insulinTypesForNewEntries.count should_not equal(0);

		[controller tableView:controller.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kSectionInsulin]];
	    });

	    it(@"should present an insulin type picker", ^{
		controller.modalViewController should_not be_nil;
	    });

	    it(@"should be set to the correct insulin type", ^{
		InsulinTypeViewController* insulinController = (InsulinTypeViewController*)controller.modalViewController;
		[insulinController insulinTypeIsSelected:[logModel.insulinTypesForNewEntries objectAtIndex:0]];
	    });
	});

	describe(@"when the dose field of the first dose row is tapped", ^{
	    __block DoseFieldCell* cell;

	    beforeEach(^{
		cell = (DoseFieldCell*)[controller.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kSectionInsulin]];
		[cell.doseField becomeFirstResponder] should be_truthy;
	    });

	    it(@"should show the keyboard", ^{
		[cell.doseField isFirstResponder] should be_truthy;
	    });

	    it(@"should have a toolbar above the keyboard", ^{
		cell.doseField.inputAccessoryView should_not be_nil;
	    });

	    describe(@"when the dose is changed", ^{
		__block NSString* originalText;

		beforeEach(^{
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

		    it(@"should restore the previous value", ^{
			cell.doseField.text should equal(originalText);
		    });
		});

		describe(@"when the accessory toolbar Done button is tapped", ^{
		    beforeEach(^{
			UIToolbar* toolbar = (UIToolbar*)cell.doseField.inputAccessoryView;
			UIBarButtonItem* doneButton = [toolbar.items objectAtIndex:2];
			[doneButton tap];
		    });

		    it(@"should resign first responder", ^{
			cell.doseField.isFirstResponder should_not be_truthy;
		    });

		    it(@"should keep the new value", ^{
			cell.doseField.text should equal(@"1");
		    });

		    it(@"should cause the next row to become first responder", ^{
			DoseFieldCell* nextCell = (DoseFieldCell*)[controller.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:kSectionInsulin]];
			nextCell.doseField.isFirstResponder should be_truthy;
		    });
		});
	    });

	    describe(@"when the dose is not changed", ^{
	    });
	});

	describe(@"when the note row is tapped", ^{
	    __block TextViewCell* cell;
	    __block NSString* originalText;

	    beforeEach(^{
		originalText = @"The Original Text";
		cell = (TextViewCell*)[controller.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kSectionNote]];
		cell.text = originalText;
		[cell.textView becomeFirstResponder] should be_truthy;
	    });

	    it(@"should become first responder", ^{
		[cell.textView isFirstResponder] should be_truthy;
	    });

	    describe(@"when the text is changed", ^{
		beforeEach(^{
		    originalText = cell.text;
		    [cell.textView replaceRange:[cell.textView textRangeFromPosition:cell.textView.beginningOfDocument toPosition:cell.textView.endOfDocument] withText:@"New Text"];
		});

		describe(@"when the input accessory Cancel button is tapped", ^{
		    beforeEach(^{
			UIToolbar* toolbar = (UIToolbar*)cell.textView.inputAccessoryView;
			UIBarButtonItem* cancelButton = [toolbar.items objectAtIndex:0];
			[cancelButton tap];
		    });

		    it(@"should resign first responder", ^{
			cell.textView.isFirstResponder should_not be_truthy;
		    });

		    it(@"should revert to the original text", ^{
			cell.text should equal(originalText);
		    });
		});

		describe(@"when the input accessory Done button is tapped", ^{
		    beforeEach(^{
			UIToolbar* toolbar = (UIToolbar*)cell.textView.inputAccessoryView;
			UIBarButtonItem* doneButton = [toolbar.items objectAtIndex:2];
			[doneButton tap];
		    });

		    it(@"should resign first responder", ^{
			cell.textView.isFirstResponder should_not be_truthy;
		    });

		    it(@"should keep the new text", ^{
			cell.text should equal(@"New Text");
		    });
		});
	    });
	});

	describe(@"when the Back button is tapped", ^{
	    __block id mockDelegate;

	    beforeEach(^{
		mockDelegate = [OCMockObject mockForProtocol:@protocol(LogEntryViewDelegate)];
		controller.delegate = mockDelegate;

		[[mockDelegate expect] logEntryViewControllerDidCancelEditing];

		id mockViewController = [OCMockObject partialMockForObject:controller];
		[[[mockViewController stub] andReturnValue:@YES] isMovingFromParentViewController];
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
	    });

	    describe(@"in general", ^{
		beforeEach(^{
		    [controller.navigationItem.rightBarButtonItem tap];
		});

		it(@"should create a new log entry", ^{
		    controller.logEntry should_not be_nil;
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

	    describe(@"when the user did not enter any insulin doses", ^{
		beforeEach(^{
		    [controller.navigationItem.rightBarButtonItem tap];
		});

		it(@"should remove invalid insulin doses", ^{
		    controller.logEntry.insulinDoses.count should equal(0);
		});

		it(@"should not show any rows in the insulin section", ^{
		    [controller.tableView numberOfRowsInSection:kSectionInsulin] should equal(0);
		});
	    });

	    describe(@"when the user entered an insulin dose", ^{
		__block DoseFieldCell* cell;

		beforeEach(^{
		    cell = (DoseFieldCell*)[controller.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kSectionInsulin]];
		    cell.doseField.text = @"1";
		    cell.insulinType should_not be_nil;

		    [controller.navigationItem.rightBarButtonItem tap];
		});

		it(@"should remove invalid insulin doses", ^{
		    controller.logEntry.insulinDoses.count should equal(1);
		});

		it(@"should have rows in the insulin section", ^{
		    [controller.tableView numberOfRowsInSection:kSectionInsulin] should equal(1);
		});
	    });
	});
    });
});

SPEC_END
