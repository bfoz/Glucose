#import "SpecsHelper.h"

#import "DateField.h"

using namespace Cedar::Matchers;

SPEC_BEGIN(DateFieldSpec)

describe(@"DateField", ^{
    __block DateField* dateField;
    __block id mockDelegate;

    beforeEach(^{
	dateField = [[DateField alloc] initWithFrame:CGRectZero];

	mockDelegate = [OCMockObject mockForProtocol:@protocol(DateFieldDelegate)];
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
	    BOOL yes = YES;
	    [[[mockDelegate expect] andReturnValue:OCMOCK_VALUE(yes)] textFieldShouldBeginEditing:dateField];
	    [dateField becomeFirstResponder];
	});

	describe(@"when the Cancel button is tapped", ^{
	    beforeEach(^{
		[[mockDelegate expect] dateFieldWillCancelEditing:OCMOCK_ANY];
		[[mockDelegate expect] textFieldDidEndEditing:OCMOCK_ANY];

		UIToolbar* toolbar = (UIToolbar*)dateField.inputAccessoryView;
		[[toolbar.items objectAtIndex:0] tap];
	    });

	    it(@"should notify the delegate", ^{
		[mockDelegate verify];
	    });

	    it(@"should resign first responder", ^{
		[dateField isFirstResponder] should_not be_truthy;
	    });
	});

	describe(@"when the Done button is tapped", ^{
	    beforeEach(^{
		[[mockDelegate expect] textFieldDidEndEditing:OCMOCK_ANY];

		UIToolbar* toolbar = (UIToolbar*)dateField.inputAccessoryView;
		[[toolbar.items objectAtIndex:2] tap];
	    });

	    it(@"should notify the delegate", ^{
		[mockDelegate verify];
	    });

	    it(@"should resign first responder", ^{
		[dateField isFirstResponder] should_not be_truthy;
	    });
	});

	describe(@"when a date is picked", ^{
	    beforeEach(^{
		[[mockDelegate expect] dateFieldDidChangeValue:OCMOCK_ANY];
		[(UIDatePicker*)dateField.inputView setDate:[NSDate date] animated:NO];
	    });

	    it(@"should notify the delegate", ^{
		[mockDelegate verify];
	    });
	});
    });
});

SPEC_END
