#import "SpecsHelper.h"

#import "CategoryViewController.h"

#import "LogModel.h"
#import "UIAlertView+Spec.h"

#import "ManagedLogEntry.h"

#define	kCategoriesSectionNumber		0
#define	kRestoreDefaultsSectionNumber		1

SPEC_BEGIN(CategoryViewControllerSpec)

describe(@"CategoryViewController", ^{
    __block CategoryViewController* controller;
    __block LogModel* logModel;

    beforeEach(^{
	logModel = [[[LogModel alloc] init] autorelease];

	controller = [[CategoryViewController alloc] initWithStyle:UITableViewStylePlain logModel:logModel];
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

    it(@"should have a None row at the top of the list", ^{
	[controller.tableView numberOfSections] should equal(1);
	UITableViewCell* cell = [controller.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kCategoriesSectionNumber]];
	cell.textLabel.text should equal(@"None");
    });

    it(@"should have 1 table section", ^{
	[controller.tableView numberOfSections] should equal(1);
    });

    it(@"should have the correct number of category rows", ^{
	[controller.tableView numberOfRowsInSection:kCategoriesSectionNumber] should equal(10);
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

	it(@"should have 2 table sections", ^{
	    [controller.tableView numberOfSections] should equal(2);
	});

	it(@"should have the correct number of category rows", ^{
	    [controller.tableView numberOfRowsInSection:kCategoriesSectionNumber] should equal(9);
	});

	it(@"should have the correct number of rows in the restore defaults section", ^{
	    [controller.tableView numberOfRowsInSection:kRestoreDefaultsSectionNumber] should equal(1);
	});

	it(@"should not have a None row at the top of the list", ^{
	    UITableViewCell* cell = [controller.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
	    cell.textLabel.text should_not equal(@"None");
	});

	describe(@"when the user deletes a Category that has log entries", ^{
	    __block TextFieldCell* deleteCell;

	    beforeEach(^{
		NSIndexPath* deleteIndexPath = [NSIndexPath indexPathForRow:1 inSection:kCategoriesSectionNumber];
		deleteCell = (TextFieldCell*)[controller.tableView cellForRowAtIndexPath:deleteIndexPath];

		ManagedLogEntry* logEntry = [logModel insertManagedLogEntry];
		logEntry.category = deleteCell.editedObject;

		[controller tableView:nil commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:deleteIndexPath];
	    });

	    it(@"should display a confirmation alert", ^{
		[UIAlertView currentAlertView] should_not be_nil;
	    });

	    describe(@"when the user taps Ok", ^{
		beforeEach(^{
		    [[UIAlertView currentAlertView] dismissWithOkButton];
		});

		it(@"should delete the row", ^{
		    [controller tableView:nil numberOfRowsInSection:kCategoriesSectionNumber] should equal(8);
		});
	    });

	    describe(@"when the user taps Cancel", ^{
		beforeEach(^{
		    [[UIAlertView currentAlertView] dismissWithCancelButton];
		});

		it(@"should not delete the row", ^{
		    [controller.tableView numberOfRowsInSection:kCategoriesSectionNumber] should equal(9);
		});
	    });
	});

	describe(@"when the user deletes a Category that does not have log entries", ^{
	    beforeEach(^{
		NSIndexPath* deleteIndexPath = [NSIndexPath indexPathForRow:1 inSection:kCategoriesSectionNumber];
		[controller tableView:nil commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:deleteIndexPath];
	    });

	    it(@"should delete the row", ^{
		[controller tableView:nil numberOfRowsInSection:kCategoriesSectionNumber] should equal(8);
	    });
	});

	describe(@"when the user moves a row", ^{
	    __block UITableViewCell* cell;
	    __block NSIndexPath*    toPath;

	    beforeEach(^{
		NSIndexPath* fromPath = [NSIndexPath indexPathForRow:5 inSection:kCategoriesSectionNumber];
		toPath = [NSIndexPath indexPathForRow:3 inSection:kCategoriesSectionNumber];

		cell = [controller.tableView cellForRowAtIndexPath:fromPath];

		[controller.tableView moveRowAtIndexPath:fromPath toIndexPath:toPath];
	    });

	    it(@"should have the same number of rows", ^{
		[controller.tableView numberOfRowsInSection:kCategoriesSectionNumber] should equal(9);
	    });

	    it(@"should move the cell", ^{
		UITableViewCell* movedCell = [controller.tableView cellForRowAtIndexPath:toPath];
		movedCell should be_same_instance_as(cell);
	    });
	});
    });
});

SPEC_END
