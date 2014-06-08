#import "SpecsHelper.h"

#import "DropboxExportViewController.h"
#import "ExportViewController.h"

using namespace Cedar::Matchers;

enum Sections
{
    kSectionRange = 0,
    kSectionExport,
    kSectionUnlink,
    NUM_SECTIONS
};

@interface DropboxExportViewController (Specs) <UITextFieldDelegate>
- (UIDatePicker*) pickerInputView;
- (id) dropboxClient;
- (void) datePickerDidChangeValue:(UIDatePicker*)sender;
@end

SPEC_BEGIN(DropboxExportViewControllerSpec)

describe(@"DropboxExportViewController", ^{
    __block DropboxExportViewController* controller;

    beforeEach(^{
	controller = [[DropboxExportViewController alloc] initWithDropboxAccount:nil dataSource:nil];
	UIViewController* top = [[UIViewController alloc] init];
	UINavigationController* navigation = [[[UINavigationController alloc] initWithRootViewController:top] autorelease];
	[navigation pushViewController:controller animated:NO];

	navigation.viewControllers.count should equal(2);

	controller.view should_not be_nil;
	[controller.tableView reloadData];
    });

    it(@"should set the title", ^{
	controller.title should equal(@"Dropbox");
    });

    it(@"should have the correct number of sections", ^{
	[controller.tableView numberOfSections] should equal(3);
    });

    it(@"should have a red Unlink Account button", ^{
	UITableViewCell* cell = [controller.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
	cell should_not be_nil;
	cell.textLabel.textColor should equal([UIColor whiteColor]);
    });

    it(@"should have a starting date range", ^{
	UITableViewCell* cell = [controller.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kSectionRange]];
	cell should_not be_nil;
    });

    it(@"should have an ending date range", ^{
	UITableViewCell* cell = [controller.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:kSectionRange]];
	cell should_not be_nil;
    });

    describe(@"when a date range row is tapped", ^{
	__block UITableViewCell* tappedCell;
	__block UITextField* editField;

	beforeEach(^{
	    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:kSectionRange];
	    tappedCell = [controller.tableView cellForRowAtIndexPath:indexPath];
	    [controller tableView:controller.tableView didSelectRowAtIndexPath:indexPath];

	    for(UIView* v in tappedCell.subviews)
	    {
		if( [v isKindOfClass:[UITextField class]] )
		{
		    editField = (UITextField*)v;
		    break;
		}
	    }
	    editField should_not be_nil;
	    [controller textFieldDidBeginEditing:editField];
	});

	it(@"should display a date picker", ^{
//	    editField.isFirstResponder should be_truthy;
	    editField.inputView should be_instance_of([UIDatePicker class]);
	});

	it(@"should have an input accessory view above the date picker", ^{
	    editField.inputAccessoryView should_not be_nil;
	    editField.inputAccessoryView should be_instance_of([UIToolbar class]);
	});

	describe(@"when the date picker is changed", ^{
	    beforeEach(^{
		controller.pickerInputView.date = [NSDate date];
		[controller datePickerDidChangeValue:controller.pickerInputView];
	    });

	    it(@"should update the label", ^{
		tappedCell.detailTextLabel.text should equal(@"Today");
	    });

	    describe(@"when the Done button is tapped", ^{
		beforeEach(^{
		    UIToolbar* toolbar = (UIToolbar*)editField.inputAccessoryView;
		    UIButton* doneButton = (UIButton*)[toolbar.items objectAtIndex:2];
		    [doneButton tap];
		    [controller textFieldDidEndEditing:editField];
		});

		it(@"should dismiss the input view", ^{
		    editField.isFirstResponder should_not be_truthy;
		});

		it(@"should update the label", ^{
		    tappedCell.detailTextLabel.text should equal(@"Today");
		});
	    });

	    describe(@"when the Cancel button is tapped", ^{
		beforeEach(^{
		    UIToolbar* toolbar = (UIToolbar*)editField.inputAccessoryView;
		    UIButton* cancelButton = (UIButton*)[toolbar.items objectAtIndex:0];
		    [cancelButton tap];
		    [controller textFieldDidEndEditing:editField];
		});

		it(@"should dismiss the input view", ^{
		    editField.isFirstResponder should_not be_truthy;
		});

		xit(@"should reset the label", ^{
		    tappedCell.detailTextLabel.text should equal(@"12/31/69");
		});
	    });
	});
    });

    describe(@"when the Export button is tapped", ^{
	it(@"should start a file upload to Dropbox", ^{
	});
    });

    describe(@"when the Unlink button is tapped", ^{
	it(@"should pop the view controller", ^{
	});

	it(@"should tell Dropbox to unlink the account", ^{
	});
    });
});

SPEC_END
