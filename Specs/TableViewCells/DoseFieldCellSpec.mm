#import "SpecsHelper.h"
#import "DoseFieldCell.h"

#import "LogModel+SpecHelper.h"
#import "ManagedLogEntry+App.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(DoseFieldCellSpec)

describe(@"DoseFieldCell", ^{
    __block DoseFieldCell* cell;
    __block LogModel*	logModel;
    __block ManagedInsulinType*	insulinType;

    beforeEach(^{
	logModel = [[[LogModel alloc] init] autorelease];

	[logModel.insulinTypesForNewEntries removeAllObjects];

	ManagedInsulinType* insulinType0 = [logModel insertManagedInsulinTypeShortName:@"InsulinType0"];
	ManagedInsulinType* insulinType1 = [logModel insertManagedInsulinTypeShortName:@"InsulinType1"];
	[logModel.insulinTypesForNewEntries addObject:insulinType0];
	[logModel.insulinTypesForNewEntries addObject:insulinType1];

	logModel.insulinTypesForNewEntries.count should equal(2);

	insulinType = [[logModel insulinTypesForNewEntries] objectAtIndex:0];
    });

    describe(@"when initialized with an Insulin Dose", ^{
	beforeEach(^{
	    ManagedLogEntry* managedLogEntry = [logModel insertManagedLogEntry];
	    ManagedInsulinDose* insulinDose = [managedLogEntry addDoseWithType:insulinType];
	    insulinDose.quantity = @2;

	    cell = [DoseFieldCell cellForInsulinDose:insulinDose
				       accessoryView:nil
					    delegate:nil
					   precision:0
					   tableView:nil];
	});

	it(@"should display the Insulin Type", ^{
	    cell.typeField.text should equal(@"InsulinType0");
	});

	it(@"should dispaly the Insulin Quantity", ^{
	    cell.doseField.text should equal(@"2");
	});
    });

    describe(@"when initialized for an Insulin Type", ^{
	beforeEach(^{

	    cell = [DoseFieldCell cellForInsulinType:insulinType
				       accessoryView:nil
					    delegate:nil
					   precision:1
					   tableView:nil];
	});

	it(@"should display the Insulin Type", ^{
	    cell.typeField.text should equal(@"InsulinType0");
	});

	it(@"should display placeholder text for the Insulin Quantity", ^{
	    cell.doseField.placeholder should equal(@"Insulin Dose");
	});
    });

    describe(@"when the dose field begins editing", ^{
	__block id mockDelegate;

	beforeEach(^{
	    ManagedLogEntry* managedLogEntry = [logModel insertManagedLogEntry];
	    ManagedInsulinDose* insulinDose = [managedLogEntry addDoseWithType:insulinType];
	    insulinDose.quantity = @2;

	    // Use nice_fake_for() because fake_for() doesn't mock optional methods
	    mockDelegate = nice_fake_for(@protocol(DoseFieldCellDelegate));

	    cell = [DoseFieldCell cellForInsulinDose:insulinDose
				       accessoryView:nil
					    delegate:mockDelegate
					   precision:0
					   tableView:nil];


	    [cell textFieldDidBeginEditing:cell.doseField];

	    cell.number = @42;
	});

	it(@"must inform the delegate", ^{
	    mockDelegate should have_received("doseDidBeginEditing:");
	});

	describe(@"when cancelled", ^{
	    beforeEach(^{
		spy_on(cell.doseField);

		[cell cancel];
	    });

	    it(@"must resign first responder", ^{
		cell.doseField should have_received("resignFirstResponder");
	    });

	    it(@"must undo any changes", ^{
		cell.number should_not equal(@42);
	    });

	    describe(@"when the field ends editing", ^{
		beforeEach(^{
		    [cell textFieldDidEndEditing:cell.doseField];
		});

		it(@"must notify the delegate", ^{
		    mockDelegate should have_received("doseDidEndEditing:");
		});
	    });
	});

	describe(@"when told to save", ^{
	    beforeEach(^{
		spy_on(cell.doseField);

		[cell save];
	    });

	    it(@"must resign first responder", ^{
		cell.doseField should have_received("resignFirstResponder");
	    });

	    it(@"should accept the new value", ^{
		cell.number should equal(@42);
	    });

	    describe(@"when the field ends editing", ^{
		beforeEach(^{
		    [cell textFieldDidEndEditing:cell.doseField];
		});

		it(@"must notify the delegate", ^{
		    mockDelegate should have_received("doseDidEndEditing:").with(cell);
		});
	    });
	});
    });
});

SPEC_END
