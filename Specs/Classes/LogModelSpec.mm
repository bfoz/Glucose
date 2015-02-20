#import "SpecsHelper.h"

#import "LogModel.h"

SPEC_BEGIN(LogModelSpec)

describe(@"LogModel", ^{
    __block LogModel* model;

    beforeEach(^{
	model = [[LogModel alloc] init];
    });

    describe(@"when deleting an insulin type", ^{
	__block ManagedInsulinType* insulinType1;
	__block ManagedInsulinType* insulinType2;
	__block ManagedInsulinType* insulinType3;

	beforeEach(^{
	    insulinType1 = [model addInsulinTypeWithName:@"Test Insulin1"];
	    insulinType2 = [model addInsulinTypeWithName:@"Test Insulin2"];
	    insulinType3 = [model addInsulinTypeWithName:@"Test Insulin3"];

	    [model addInsulinTypeForNewEntries:insulinType1];
	    [model addInsulinTypeForNewEntries:insulinType2];
	    [model addInsulinTypeForNewEntries:insulinType3];

	    spy_on(model.managedObjectContext);

	    [model removeInsulinType:insulinType2];
	});

	it(@"must remove it from the insulin types property", ^{
	    model.insulinTypes should_not contain(insulinType2);
	});

	it(@"must remove it from the insulin types for new entries property", ^{
	    model.insulinTypesForNewEntries should_not contain(insulinType2);
	});

	it(@"must remove it from the backing store", ^{
	    model.managedObjectContext should have_received("deleteObject:").with(Arguments::anything);
	});
    });
});

SPEC_END
