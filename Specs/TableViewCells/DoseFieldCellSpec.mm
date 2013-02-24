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
	    insulinDose.dose = @2;

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
	    cell.doseField.placeholder should equal(@"Insulin");
	});
    });
});

SPEC_END
