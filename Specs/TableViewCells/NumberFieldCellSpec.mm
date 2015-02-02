#import "SpecsHelper.h"
#import "NumberFieldCell.h"

#import "LogModel+SpecHelper.h"

SPEC_BEGIN(NumberFieldCellSpec)

describe(@"NumberFieldCell", ^{
    __block NumberFieldCell* cell;
    __block id delegate;

    beforeEach(^{
	delegate = nice_fake_for(@protocol(NumberFieldCellDelegate));

	cell = [NumberFieldCell cellForNumber:@5
				    precision:1
				  unitsString:[NSString stringWithFormat:@" %@", [LogModel glucoseUnitsSettingString]]
			   inputAccessoryView:nil
				     delegate:delegate
				    tableView:nil];
    });

    describe(@"when the value is changed", ^{
	beforeEach(^{
	    [cell becomeFirstResponder];
	    [cell textFieldDidBeginEditing:cell.field];

	    cell.number = @42;
	});

	describe(@"when cancelled", ^{
	    beforeEach(^{
		spy_on(delegate);
		spy_on(cell.field);

		[cell cancel];
	    });

	    it(@"must resign first responder", ^{
		cell.field should have_received("resignFirstResponder");
	    });

	    it(@"must undo any changes", ^{
		cell.number should_not equal(@42);
	    });

	    describe(@"when the field ends editing", ^{
		beforeEach(^{
		    [cell textFieldDidEndEditing:cell.field];
		});

		it(@"must notify the delegate", ^{
		    delegate should have_received("numberFieldCellDidEndEditing:").with(Arguments::anything);
		});
	    });
	});

	describe(@"when told to save", ^{
	    beforeEach(^{
		spy_on(delegate);
		spy_on(cell.field);

		[cell save];
	    });

	    it(@"must resign first responder", ^{
		cell.field should have_received("resignFirstResponder");
	    });

	    it(@"should accept the new value", ^{
		cell.number should equal(@42);
	    });

	    describe(@"when the field ends editing", ^{
		beforeEach(^{
		    [cell textFieldDidEndEditing:cell.field];
		});

		it(@"must notify the delegate", ^{
		    delegate should have_received("numberFieldCellDidEndEditing:").with(Arguments::anything);
		});
	    });
	});
    });
});

SPEC_END
