#import "SpecsHelper.h"

#import "DateField.h"

SPEC_BEGIN(DateFieldSpec)

describe(@"DateField", ^{
    __block DateField* dateField;
    __block id mockDelegate;

    beforeEach(^{
	dateField = [[DateField alloc] initWithFrame:CGRectZero];

	mockDelegate = fake_for(@protocol(DateFieldDelegate));
	dateField.delegate = mockDelegate;
    });

    it(@"should have a UIDatePicker for an input view", ^{
	dateField.inputView should be_instance_of([UIDatePicker class]);
    });

    it(@"should have a toolbar for an input accessory view", ^{
	dateField.inputAccessoryView should be_instance_of([UIToolbar class]);
    });

    describe(@"toolbar", ^{
	__block UIToolbar* toolbar;

	beforeEach(^{
	    toolbar = (UIToolbar*)dateField.inputAccessoryView;
	});

	it(@"should have a Cancel button on the toolbar", ^{
	    [toolbar.items objectAtIndex:0] should be_instance_of([UIBarButtonItem class]);
	});

	it(@"should have a Done button on the toolbar", ^{
	    [toolbar.items objectAtIndex:2] should be_instance_of([UIBarButtonItem class]);
	});
    });

    xdescribe(@"when firstResponder", ^{
	beforeEach(^{
	    mockDelegate stub_method(@selector(textFieldShouldBeginEditing:)).with(dateField).and_return(YES);
	    [dateField becomeFirstResponder];
	});

	describe(@"when the Cancel button is tapped", ^{
	    beforeEach(^{
		UIToolbar* toolbar = (UIToolbar*)dateField.inputAccessoryView;
		[[toolbar.items objectAtIndex:0] tap];
	    });

	    it(@"should notify the delegate", ^{
		mockDelegate should have_received("dateFieldWillCancelEditing:").with(Arguments::anything);
		mockDelegate should have_received("textFieldDidEndEditing:").with(Arguments::anything);
	    });

	    it(@"should resign first responder", ^{
		[dateField isFirstResponder] should_not be_truthy;
	    });
	});

	describe(@"when the Done button is tapped", ^{
	    beforeEach(^{
		UIToolbar* toolbar = (UIToolbar*)dateField.inputAccessoryView;
		[[toolbar.items objectAtIndex:2] tap];
	    });

	    it(@"should notify the delegate", ^{
		mockDelegate should have_received("textFieldDidEndEditing:").with(Arguments::anything);
	    });

	    it(@"should resign first responder", ^{
		[dateField isFirstResponder] should_not be_truthy;
	    });
	});

	describe(@"when a date is picked", ^{
	    beforeEach(^{
		[(UIDatePicker*)dateField.inputView setDate:[NSDate date] animated:NO];
	    });

	    it(@"should notify the delegate", ^{
		mockDelegate should have_received("dateFieldDidChangeValue:").with(Arguments::anything);
	    });
	});
    });
});

SPEC_END
