#import "SpecsHelper.h"

#import "EditTextViewController.h"

@interface EditTextViewController ()
- (void) didTapCancelButton;
- (void) didTapSaveButton;
@end

SPEC_BEGIN(EditTextViewControllerSpec)

describe(@"EditTextViewController", ^{
    __block EditTextViewController* controller;
    __block id mockDelegate;

    beforeEach(^{
	mockDelegate = nice_fake_for(@protocol(EditTextViewControllerDelegate));

	controller = [[EditTextViewController alloc] initWithText:@"Some Text"];
	controller.delegate = mockDelegate;
    });

    describe(@"when the Cancel button is tapped", ^{
	beforeEach(^{
	    [controller didTapCancelButton];
	});

	it(@"must inform the delegate with nil text", ^{
	    mockDelegate should have_received(@selector(editTextViewControllerDidFinishWithText:)).with(nil);
	});
    });

    describe(@"when the Save button is tapped", ^{
	beforeEach(^{
	    [controller didTapSaveButton];
	});

	it(@"must inform the delegate with the text", ^{
	    mockDelegate should have_received(@selector(editTextViewControllerDidFinishWithText:)).with(@"Some Text");
	});
    });
});

SPEC_END
