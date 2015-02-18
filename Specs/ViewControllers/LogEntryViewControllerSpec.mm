#import "SpecsHelper.h"

#import "ManagedCategory.h"
#import "ManagedLogDay+App.h"
#import "ManagedLogEntry+App.h"

#import "DateField.h"
#import "DoseFieldCell.h"
#import "EditTextViewController.h"
#import "InsulinTypeViewController.h"
#import "LogEntryViewController.h"
#import "LogModel+SpecHelper.h"
#import "NumberFieldCell.h"
#import "TextViewCell.h"

enum Sections
{
    kSectionGlucose = 0,
    kSectionInsulin,
    kSectionNote,
    NUM_SECTIONS
};

@interface LogEntryViewController (UISpecs) <DateFieldDelegate, DoseFieldCellDelegate, EditTextViewControllerDelegate, NumberFieldCellDelegate>
@property (nonatomic, strong) UILabel*	    categoryLabel;
@property (nonatomic, strong) NumberFieldCell*	glucoseCell;
@property (nonatomic, strong) DateField*    timestampField;
@property (nonatomic, strong) UILabel*	    timestampLabel;

- (void) categoryViewControllerDidSelectCategory:(id)category;
- (void) didTapToolbarCancelButton;
- (void) didTapDoneButton;
@end

SPEC_BEGIN(LogEntryViewControllerSpec)

describe(@"LogEntryViewController", ^{
    __block LogEntryViewController* controller;
    __block ManagedLogEntry*	logEntry;
    __block LogModel*	logModel;

    beforeEach(^{
	logModel = [[LogModel alloc] init];
    });

    describe(@"when displaying an existing log entry", ^{
	__block UINavigationController* navigationController;

	beforeEach(^{
	    logEntry = [logModel insertManagedLogEntry];

	    controller = [[LogEntryViewController alloc] initWithLogEntry:logEntry];
	    controller.model = logModel;

	    UIViewController* rootViewController = [[UIViewController alloc] init];
	    navigationController = [[UINavigationController alloc] initWithRootViewController:rootViewController];
	    [navigationController pushViewController:controller animated:NO];
	    navigationController.topViewController.view should_not be_nil;

	    [controller viewDidLoad];
	});

	it(@"should not be editing", ^{
	    controller.editing should_not be_truthy;
	    controller.editingNewEntry should_not be_truthy;
	});

	it(@"should have a right bar button item for editing", ^{
	    controller.navigationItem.rightBarButtonItem should_not be_nil;
	    controller.navigationItem.rightBarButtonItem should be_same_instance_as(controller.editButtonItem);
	});

	it(@"must have a table view", ^{
	    controller.tableView should_not be_nil;
	    controller.tableView should be_instance_of(UITableView.class);
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
		insulinDose.quantity = @1;
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
		insulinDose.quantity = @1;
		insulinDose = [logEntry addDoseWithType:insulinType1];
		insulinDose.quantity = @2;
	    });

	    it(@"should show two dose rows", ^{
		[controller.tableView numberOfRowsInSection:kSectionInsulin] should equal(2);
	    });

	    it(@"should not have a section header", ^{
		[controller tableView:nil titleForHeaderInSection:kSectionInsulin] should be_nil;
	    });
	});

	describe(@"when the log entry has a note", ^{
	    __block NSIndexPath*    noteRowIndexPath;
	    __block NSString* noteText;

	    beforeEach(^{
		noteRowIndexPath = [NSIndexPath indexPathForRow:0 inSection:kSectionNote];
		noteText = @"This is a note that is supposed to span multiple lines. I have no idea if it really does, but we shall see.";
		logEntry.note = noteText;
		controller.logEntry = logEntry;

		[controller.tableView reloadData];
	    });

	    it(@"should display a header for the Note section", ^{
		[controller tableView:nil titleForHeaderInSection:kSectionNote] should equal(@"Note");
	    });

	    it(@"should have 1 row in the Note section", ^{
		[controller.tableView numberOfRowsInSection:kSectionNote] should equal(1);
	    });

	    it(@"should have the correct text", ^{
		UITableViewCell* cell = [controller.tableView cellForRowAtIndexPath:noteRowIndexPath];
		cell.textLabel.text should equal(noteText);
	    });

	    it(@"should left justify the text", ^{
		UITableViewCell* cell = [controller.tableView cellForRowAtIndexPath:noteRowIndexPath];
		cell.textLabel.textAlignment should equal(NSTextAlignmentLeft);
	    });

	    it(@"should resize the cell to accommodate the note", ^{
		[controller tableView:nil heightForRowAtIndexPath:noteRowIndexPath] should_not equal(44);
	    });

	    it(@"should not do anything when the row is tapped", ^{
		[controller tableView:nil didSelectRowAtIndexPath:noteRowIndexPath];
		controller.navigationController.topViewController should be_instance_of([LogEntryViewController class]);
	    });

	    it(@"should not have a disclosure indicator", ^{
		UITableViewCell* cell = [controller.tableView cellForRowAtIndexPath:noteRowIndexPath];
		cell.accessoryType should equal(UITableViewCellAccessoryNone);
	    });
	});

	describe(@"when the log entry does not have a note", ^{
	    __block NSIndexPath*    noteRowIndexPath;

	    beforeEach(^{
		noteRowIndexPath = [NSIndexPath indexPathForRow:0 inSection:kSectionNote];
		logEntry.note = nil;
	    });

	    it(@"should not display a header for the Note section", ^{
		[controller tableView:nil titleForHeaderInSection:kSectionNote] should be_nil;
	    });

	    it(@"should not have any rows in the Note section", ^{
		[controller.tableView numberOfRowsInSection:kSectionNote] should equal(0);
	    });

	    it(@"should set the cell height to the standard value", ^{
		[controller tableView:nil heightForRowAtIndexPath:noteRowIndexPath] should equal(44);
	    });

	    it(@"should not do anything when the row is tapped", ^{
		[controller tableView:nil didSelectRowAtIndexPath:noteRowIndexPath];
		controller.navigationController.topViewController should be_instance_of([LogEntryViewController class]);
	    });
	});

	describe(@"when the Edit button is tapped", ^{
	    beforeEach(^{
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

		context(@"Row 2 (Glucose)", ^{
		    __block NumberFieldCell* cell;
		    __block NSIndexPath* indexPath =[NSIndexPath indexPathForRow:2 inSection:0];

		    beforeEach(^{
			cell = (NumberFieldCell*)[controller.tableView cellForRowAtIndexPath:indexPath];
		    });

		    it(@"must be a NumberFieldCell", ^{
			cell should be_instance_of(NumberFieldCell.class);
		    });

		    it(@"must have a delegate", ^{
			cell.delegate should be_same_instance_as(controller);
		    });

		    describe(@"when the cell is tapped", ^{
			beforeEach(^{
			    spy_on(cell);
			    cell.field should_not be_nil;

			    [controller tableView:controller.tableView didSelectRowAtIndexPath:indexPath];
			});

			it(@"should display the keyboard", ^{
			    cell should have_received("becomeFirstResponder");
			});

			it(@"should have Cancel and Done buttons above the keyboard", ^{
			    UIToolbar* toolbar = (UIToolbar*)cell.field.inputAccessoryView;
			    toolbar should_not be_nil;
			    toolbar should be_instance_of([UIToolbar class]);
			    toolbar.items.count should equal(3);
			});
		    });

		    describe(@"when the Glucose cell begins editing", ^{
			beforeEach(^{
			    [controller numberFieldCellDidBeginEditing:cell];
			});

			it(@"should disable the Save button", ^{
			    controller.navigationItem.rightBarButtonItem.enabled should_not be_truthy;
			});

			describe(@"when the Cancel button is tapped", ^{
			    beforeEach(^{
				spy_on(cell);

				[controller didTapToolbarCancelButton];
			    });

			    it(@"must inform the cell", ^{
				cell should have_received("cancel");
			    });

			    describe(@"when the cell ends editing", ^{
				beforeEach(^{
				    [controller numberFieldCellDidEndEditing:cell];
				});

				it(@"should enable the right nav bar button", ^{
				    controller.navigationItem.rightBarButtonItem.enabled should be_truthy;
				});
			    });
			});

			describe(@"when the Done button is tapped", ^{
			    beforeEach(^{
				spy_on(cell);

				[controller didTapDoneButton];
			    });

			    it(@"must inform the cell", ^{
				cell should have_received("save");
			    });

			    describe(@"when the cell ends editing", ^{
				beforeEach(^{
				    [controller numberFieldCellDidEndEditing:cell];
				});

				it(@"should enable the right nav bar button", ^{
				    controller.navigationItem.rightBarButtonItem.enabled should be_truthy;
				});
			    });
			});
		    });
		});
	    });

	    it(@"should have the proper number of insulin rows", ^{
		[controller.tableView numberOfRowsInSection:kSectionInsulin] should equal(logEntry.insulinDoses.count);
	    });

	    describe(@"Section 2 - Note", ^{
		__block UITableViewCell* cell;
		__block NSIndexPath*    noteRowIndexPath = [NSIndexPath indexPathForRow:0 inSection:kSectionNote];

		it(@"should have 1 row", ^{
		    [controller.tableView numberOfRowsInSection:kSectionNote] should equal(1);
		});

		it(@"should have a disclosure indicator", ^{
		    UITableViewCell* cell = [controller.tableView cellForRowAtIndexPath:noteRowIndexPath];
		    cell.accessoryType should equal(UITableViewCellAccessoryDisclosureIndicator);
		});

		describe(@"when the log entry already had a note", ^{
		    __block NSString* noteText;
		    __block CGFloat originalCellHeight;

		    beforeEach(^{
			noteText = @"This is some note text";
			logEntry.note = noteText;
			controller.logEntry = logEntry;

			cell = [controller.tableView cellForRowAtIndexPath:noteRowIndexPath];
			originalCellHeight = [controller tableView:nil heightForRowAtIndexPath:noteRowIndexPath];
		    });

		    it(@"should show the note text in the cell", ^{
			cell.textLabel.text should equal(noteText);
		    });

		    it(@"should left justify the text", ^{
			UITableViewCell* cell = [controller.tableView cellForRowAtIndexPath:noteRowIndexPath];
			cell.textLabel.textAlignment should equal(NSTextAlignmentLeft);
		    });

		    it(@"should display a header for the Note section", ^{
			[controller tableView:nil titleForHeaderInSection:kSectionNote] should equal(@"Note");
		    });

		    describe(@"when the row is tapped", ^{
			beforeEach(^{
			    NSLog(@"%ld %ld", (long)noteRowIndexPath.section, (long)noteRowIndexPath.row);
			    [controller tableView:nil didSelectRowAtIndexPath:noteRowIndexPath];
			});

			it(@"should display the edit text view", ^{
			    controller.presentedViewController should be_instance_of([UINavigationController class]);
			    ((UINavigationController*)controller.presentedViewController).topViewController should be_instance_of([EditTextViewController class]);
			});

			it(@"should set the initial text for the edit text view", ^{
			    EditTextViewController* editController = (EditTextViewController*)(((UINavigationController*)controller.presentedViewController).topViewController);
			    editController.text should equal(noteText);
			});

			describe(@"when the edit controller returns with text", ^{
			    __block NSString* newNoteText;

			    beforeEach(^{
				newNoteText = @"This is new text that the user has entered. Although it could be the orignal text too.";
				[controller editTextViewControllerDidFinishWithText:newNoteText];
			    });

			    it(@"should update the cell text", ^{
				UITableViewCell* cell = [controller.tableView cellForRowAtIndexPath:noteRowIndexPath];
				cell.textLabel.text should equal(newNoteText);
			    });

			    it(@"should update the cell height", ^{
				[controller tableView:nil heightForRowAtIndexPath:noteRowIndexPath] should_not equal(44);
			    });
			});

			describe(@"when the edit controller returns empty text", ^{
			    beforeEach(^{
				[controller editTextViewControllerDidFinishWithText:@""];
			    });

			    it(@"should set the cell to Add a Note", ^{
				UITableViewCell* cell = [controller.tableView cellForRowAtIndexPath:noteRowIndexPath];
				cell.textLabel.text should equal(@"Add a Note");
			    });

			    it(@"should return the cell height to the standard value", ^{
				[controller tableView:nil heightForRowAtIndexPath:noteRowIndexPath] should equal(44);
			    });
			});

			describe(@"when the edit controller cancels the edit", ^{
			    beforeEach(^{
				[controller editTextViewControllerDidFinishWithText:nil];
			    });

			    it(@"should set the cell to the original text", ^{
				UITableViewCell* cell = [controller.tableView cellForRowAtIndexPath:noteRowIndexPath];
				cell.textLabel.text should equal(noteText);
			    });

			    it(@"should return the cell height to the original value", ^{
				[controller tableView:nil heightForRowAtIndexPath:noteRowIndexPath] should equal(originalCellHeight);
			    });
			});
		    });

		    describe(@"when the row is deleted", ^{
			beforeEach(^{
			    [controller tableView:controller.tableView
			       commitEditingStyle:UITableViewCellEditingStyleDelete
				forRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kSectionNote]];
			});

			it(@"must set the cell to Add a Note", ^{
			    cell.textLabel.text should equal(@"Add a Note");
			});

			it(@"should not display a header for the Note section", ^{
			    [controller tableView:nil titleForHeaderInSection:kSectionNote] should be_nil;
			});

			it(@"should center justify the text", ^{
			    UITableViewCell* cell = [controller.tableView cellForRowAtIndexPath:noteRowIndexPath];
			    cell.textLabel.textAlignment should equal(NSTextAlignmentCenter);
			});

			it(@"should set the cell height to the standard value", ^{
			    [controller tableView:nil heightForRowAtIndexPath:noteRowIndexPath] should equal(44);
			});
		    });
		});

		describe(@"when the log entry did not have a note", ^{
		    beforeEach(^{
			logEntry.note = nil;
			controller.logEntry = logEntry;

			cell = [controller.tableView cellForRowAtIndexPath:noteRowIndexPath];
		    });

		    it(@"should not display a header for the Note section", ^{
			[controller tableView:nil titleForHeaderInSection:kSectionNote] should be_nil;
		    });

		    it(@"should set the cell text to Add a Note", ^{
			cell.textLabel.text should equal(@"Add a Note");
		    });

		    it(@"should center justify the text", ^{
			UITableViewCell* cell = [controller.tableView cellForRowAtIndexPath:noteRowIndexPath];
			cell.textLabel.textAlignment should equal(NSTextAlignmentCenter);
		    });

		    it(@"should set the cell height to the standard value", ^{
			[controller tableView:nil heightForRowAtIndexPath:noteRowIndexPath] should equal(44);
		    });

		    describe(@"when the row is tapped", ^{
			beforeEach(^{
			    [controller tableView:nil didSelectRowAtIndexPath:noteRowIndexPath];
			});

			it(@"should display the edit text view", ^{
			    controller.presentedViewController should be_instance_of([UINavigationController class]);
			    ((UINavigationController*)controller.presentedViewController).topViewController should be_instance_of([EditTextViewController class]);
			});

			it(@"should set the initial text for the edit text view", ^{
			    EditTextViewController* editController = (EditTextViewController*)(((UINavigationController*)controller.presentedViewController).topViewController);
			    editController.text.length should equal(0);
			});

			describe(@"when the edit controller returns with text", ^{
			    __block UITableViewCell* cell;
			    __block NSString* newNoteText;

			    beforeEach(^{
				newNoteText = @"This is new text that the user has entered. Although it could be the orignal text too.";
				[controller editTextViewControllerDidFinishWithText:newNoteText];
				cell = [controller.tableView cellForRowAtIndexPath:noteRowIndexPath];
			    });

			    it(@"should update the cell text", ^{
				cell.textLabel.text should equal(newNoteText);
			    });

			    it(@"should left justify the text", ^{
				cell.textLabel.textAlignment should equal(NSTextAlignmentLeft);
			    });

			    it(@"should update the cell height", ^{
				[controller tableView:nil heightForRowAtIndexPath:noteRowIndexPath] should_not equal(44);
			    });
			});

			describe(@"when the edit controller returns with no text", ^{
			    __block UITableViewCell* cell;

			    beforeEach(^{
				[controller editTextViewControllerDidFinishWithText:nil];
				cell = [controller.tableView cellForRowAtIndexPath:noteRowIndexPath];
			    });

			    it(@"should keep the Add a Note a cell", ^{
				UITableViewCell* cell = [controller tableView:controller.tableView cellForRowAtIndexPath:noteRowIndexPath];
				cell.textLabel.text should equal(@"Add a Note");
			    });

			    it(@"should center justify the text", ^{
				UITableViewCell* cell = [controller tableView:controller.tableView cellForRowAtIndexPath:noteRowIndexPath];
				cell.textLabel.textAlignment should equal(NSTextAlignmentCenter);
			    });

			    it(@"should keep the standard cell height", ^{
				[controller tableView:nil heightForRowAtIndexPath:noteRowIndexPath] should equal(44);
			    });
			});
		    });
		});
	    });

	    describe(@"when the Save button is tapped", ^{
		beforeEach(^{
		    spy_on(controller.model);

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
		    controller.model should have_received("commitChanges");
		});
	    });
	});
    });

    describe(@"when initialized for a new entry", ^{
	beforeEach(^{
	    UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:[[UIViewController alloc] init]];

	    controller = [[LogEntryViewController alloc] initWithLogModel:logModel];

	    [navigationController pushViewController:controller animated:YES];

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

	describe(@"Section 2 - Note", ^{
	    __block NSIndexPath*    noteRowIndexPath;

	    beforeEach(^{
		noteRowIndexPath = [NSIndexPath indexPathForRow:0 inSection:kSectionNote];
	    });

	    it(@"should have 1 row", ^{
		[controller.tableView numberOfRowsInSection:2] should equal(1);
	    });

	    it(@"should show a disclosure indicator", ^{
		UITableViewCell* cell = [controller.tableView cellForRowAtIndexPath:noteRowIndexPath];
		cell.accessoryType should equal(UITableViewCellAccessoryDisclosureIndicator);
	    });

	    it(@"should have an Add a Note row", ^{
		UITableViewCell* cell = [controller.tableView cellForRowAtIndexPath:noteRowIndexPath];
		cell.textLabel.text should equal(@"Add a Note");
	    });

	    it(@"should center justify the text", ^{
		UITableViewCell* cell = [controller tableView:controller.tableView cellForRowAtIndexPath:noteRowIndexPath];
		cell.textLabel.textAlignment should equal(NSTextAlignmentCenter);
	    });
	});

	describe(@"when the timestamp row is tapped", ^{
	    beforeEach(^{
		[controller.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];

		spy_on(controller.timestampField);

		[controller tableView:nil didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kSectionGlucose]];
	    });

	    it(@"must have a delegate", ^{
		controller.timestampField.delegate should be_same_instance_as(controller);
	    });

	    it(@"should become first responder", ^{
		controller.timestampField should have_received("becomeFirstResponder");
	    });

	    describe(@"when the timestamp field begins editing", ^{
		beforeEach(^{
		    [controller textFieldDidBeginEditing:controller.timestampField];
		});

		it(@"must disable the right nav bar button", ^{
		    controller.navigationItem.rightBarButtonItem.enabled should_not be_truthy;
		});
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

		    it(@"should restore the original date", ^{
			controller.timestampField.date = originalDate;
		    });

		    describe(@"when the field ends editing", ^{
			beforeEach(^{
			    [controller textFieldDidEndEditing:controller.timestampField];
			});

			it(@"should enable the right nav bar button", ^{
			    controller.navigationItem.rightBarButtonItem.enabled should be_truthy;
			});
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
		spy_on(controller);

		// Force the Category cell into existence
		NSIndexPath* indexPath = [NSIndexPath indexPathForRow:1 inSection:kSectionGlucose];
		[controller.tableView cellForRowAtIndexPath:indexPath];

		[controller tableView:controller.tableView didSelectRowAtIndexPath:indexPath];
	    });

	    it(@"should display a modal Category picker", ^{
		controller should have_received("presentViewController:animated:completion:").with(Arguments::anything, YES, nil);
	    });

	    describe(@"when a Category is picked", ^{
		__block ManagedCategory* category;

		beforeEach(^{
		    spy_on(controller);
		    spy_on(controller.glucoseCell);

		    category = [logModel addCategoryWithName:@"TestCategory"];

		    [controller categoryViewControllerDidSelectCategory:category];
		    [controller viewDidAppear:NO];
		});

		it(@"should dismiss the picker", ^{
		    controller should have_received("dismissViewControllerAnimated:completion:").with(YES, nil);
		});

		it(@"should update the Category label", ^{
		    controller.categoryLabel.text should equal(category.name);
		    controller.categoryLabel.textColor should_not equal([UIColor lightGrayColor]);
		});

		it(@"should make the Glucose row the first responder", ^{
		    controller.glucoseCell should have_received("becomeFirstResponder");
		});
	    });
	});

	describe(@"when the note row is tapped", ^{
	    __block UITableViewCell* cell;
	    __block NSIndexPath*    noteRowIndexPath;

	    beforeEach(^{
		spy_on(controller);

		noteRowIndexPath = [NSIndexPath indexPathForRow:0 inSection:kSectionNote];
		cell = [controller.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kSectionNote]];

		[controller tableView:nil didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kSectionNote]];
	    });

	    it(@"should display an edit text view controller", ^{
		controller should have_received("presentViewController:animated:completion:").with(Arguments::anything, YES, nil);
	    });

	    describe(@"when the edit text view returns", ^{
		__block NSString* noteText;

		describe(@"with text", ^{
		    beforeEach(^{
			noteText = @"This is some very fine note text. Some might even call it noteworthy.";
			[controller editTextViewControllerDidFinishWithText:noteText];
		    });

		    it(@"should update the button with the text", ^{
			cell.textLabel.text should equal(noteText);
		    });

		    it(@"should left justify the text", ^{
			UITableViewCell* cell = [controller tableView:controller.tableView cellForRowAtIndexPath:noteRowIndexPath];
			cell.textLabel.textAlignment should equal(NSTextAlignmentLeft);
		    });

		    it(@"should put a disclosure arrow on the cell", ^{
			cell.accessoryType should equal(UITableViewCellAccessoryDisclosureIndicator);
		    });

		    it(@"should have the correct section title", ^{
			[controller tableView:nil titleForHeaderInSection:kSectionNote] should equal(@"Note");
		    });
		});

		describe(@"with empty text", ^{
		    beforeEach(^{
			[controller editTextViewControllerDidFinishWithText:@""];
		    });

		    it(@"should change the button to say Add a Note", ^{
			cell.textLabel.text should equal(@"Add a Note");
		    });

		    it(@"should center justify the text", ^{
			UITableViewCell* cell = [controller tableView:controller.tableView cellForRowAtIndexPath:noteRowIndexPath];
			cell.textLabel.textAlignment should equal(NSTextAlignmentCenter);
		    });

		    it(@"should show the disclosure indicator", ^{
			cell.accessoryType should equal(UITableViewCellAccessoryDisclosureIndicator);
		    });

		    it(@"should not have a section title", ^{
			[controller tableView:nil titleForHeaderInSection:kSectionNote] should be_nil;
		    });
		});

		describe(@"without text", ^{
		    beforeEach(^{
			[controller editTextViewControllerDidFinishWithText:nil];
		    });

		    it(@"should change the button to say Add a Note", ^{
			cell.textLabel.text should equal(@"Add a Note");
		    });

		    it(@"should center justify the text", ^{
			UITableViewCell* cell = [controller tableView:controller.tableView cellForRowAtIndexPath:noteRowIndexPath];
			cell.textLabel.textAlignment should equal(NSTextAlignmentCenter);
		    });

		    it(@"should show the disclosure indicator", ^{
			cell.accessoryType should equal(UITableViewCellAccessoryDisclosureIndicator);
		    });

		    it(@"should not have a section title", ^{
			[controller tableView:nil titleForHeaderInSection:kSectionNote] should be_nil;
		    });
		});
	    });
	});

	describe(@"when the Done button is tapped", ^{
	    beforeEach(^{
		controller.delegate = nice_fake_for(@protocol(LogEntryViewDelegate));
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
		    controller.delegate should have_received("logEntryView:didEndEditingEntry:").with(controller, Arguments::anything);
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
	});

	describe(@"when there are no insulins for new entries", ^{
	    beforeEach(^{
		logModel.insulinTypesForNewEntries.count should equal(0);
	    });

	    it(@"should have the proper number of insulin rows", ^{
		[controller.tableView numberOfRowsInSection:kSectionInsulin] should equal(logModel.insulinTypesForNewEntries.count);
	    });
	});

	describe(@"when there are insulins for new entries", ^{
	    beforeEach(^{
		ManagedInsulinType* insulinType0 = [logModel insertManagedInsulinTypeShortName:@"InsulinType0"];
		ManagedInsulinType* insulinType1 = [logModel insertManagedInsulinTypeShortName:@"InsulinType1"];
		[logModel.insulinTypesForNewEntries addObject:insulinType0];
		[logModel.insulinTypesForNewEntries addObject:insulinType1];

		logModel.insulinTypesForNewEntries.count should equal(2);

		UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:[[UIViewController alloc] init]];

		controller = [[LogEntryViewController alloc] initWithLogModel:logModel];

		[navigationController pushViewController:controller animated:NO];

		UIWindow* window = [[UIWindow alloc] init];
		window.rootViewController = navigationController;
		[window makeKeyAndVisible];

		[controller.tableView reloadData];
	    });

	    it(@"should have the proper number of insulin rows", ^{
		[controller.tableView numberOfRowsInSection:kSectionInsulin] should equal(logModel.insulinTypesForNewEntries.count);
	    });

	    it(@"must be the delegate for all of the insulin rows", ^{
	    });

	    it(@"should set the editing style for insulin rows", ^{
		DoseFieldCell* cell = (DoseFieldCell*)[controller.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kSectionInsulin]];
		cell.editingStyle should equal(UITableViewCellEditingStyleDelete);
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

	    describe(@"when the dose field of the first dose row begins editing", ^{
		__block DoseFieldCell* cell;

		beforeEach(^{
		    cell = (DoseFieldCell*)[controller.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kSectionInsulin]];

		    [controller doseDidBeginEditing:cell];
		});

		it(@"should disable the Save button", ^{
		    controller.navigationItem.rightBarButtonItem.enabled should_not be_truthy;
		});

		// This is checked here, instead of in DoseFieldCellSpec, because
		//  the ViewController assigns the accessory view to the cell.
		it(@"should have a toolbar above the keyboard", ^{
		    cell.doseField.inputAccessoryView should_not be_nil;
		});

		// This is checked here, instead of in DoseFieldCellSpec, because
		//  the ViewController assigns the accessory view to the cell.
		it(@"should have Cancel and Done buttons above the keyboard", ^{
		    UIToolbar* toolbar = (UIToolbar*)cell.doseField.inputAccessoryView;
		    toolbar should_not be_nil;
		    toolbar should be_instance_of([UIToolbar class]);
		    toolbar.items.count should equal(3);
		});

		describe(@"when the accessory toolbar Cancel button is tapped", ^{
		    beforeEach(^{
			spy_on(cell);

			UIToolbar* toolbar = (UIToolbar*)cell.doseField.inputAccessoryView;
			UIBarButtonItem* cancelButton = [toolbar.items objectAtIndex:0];
			[cancelButton tap];
		    });

		    it(@"must inform the cell", ^{
			cell should have_received("cancel");
		    });
		});

		describe(@"when the accessory toolbar Done button is tapped", ^{
		    beforeEach(^{
			spy_on(cell);
			spy_on(controller);

			UIToolbar* toolbar = (UIToolbar*)cell.doseField.inputAccessoryView;
			UIBarButtonItem* doneButton = [toolbar.items objectAtIndex:2];
			[doneButton tap];
		    });

		    it(@"must inform the cell", ^{
			cell should have_received("save");
		    });

		    describe(@"when the cell ends editing", ^{
			__block DoseFieldCell* nextCell;

			beforeEach(^{
			    nextCell = (DoseFieldCell*)[controller.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:kSectionInsulin]];
			    spy_on(nextCell.doseField);

			    [controller doseDidEndEditing:cell];
			});

			it(@"should cause the next row to become first responder", ^{
			    nextCell.doseField should have_received("becomeFirstResponder");
			});
		    });
		});
	    });

	    describe(@"when the Done button is tapped", ^{
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
});

SPEC_END
