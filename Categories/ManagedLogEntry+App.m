#import "LogModel.h"

#import "ManagedLogEntry+App.h"

#import "ManagedInsulinDose.h"

@implementation ManagedLogEntry (App)

+ (ManagedLogEntry*) insertManagedLogEntryInContext:(NSManagedObjectContext*)managedObjectContext
{
    ManagedLogEntry* managedLogEntry = [NSEntityDescription insertNewObjectForEntityForName:@"LogEntry" inManagedObjectContext:managedObjectContext];
    return managedLogEntry;
}

- (NSString*) glucoseString
{
    if( self.glucose && ![self.glucose isEqualToNumber:[NSNumber numberWithInt:0]] )
    {
	if( self.glucoseUnits )
	    return [NSString localizedStringWithFormat:@"%.*f %@", self.glucosePrecision, [self.glucose floatValue], self.glucoseUnitsString];
	else
	    return [NSString localizedStringWithFormat:@"%.0f", [self.glucose floatValue]];
    }

    return nil;
}

- (BOOL) is_mgdL
{
    return [self.glucoseUnits intValue] == kGlucoseUnits_mgdL;
}

- (NSString*) glucoseUnitsString
{
    return [self is_mgdL] ? GlucoseUnitsTypeString_mgdL : GlucoseUnitsTypeString_mmolL;
}

- (unsigned) glucosePrecision
{
    return [self is_mgdL] ? 0 : 1;
}

- (ManagedInsulinDose*) addDoseWithType:(ManagedInsulinType*)insulinType
{
    ManagedInsulinDose* managedInsulinDose = [NSEntityDescription insertNewObjectForEntityForName:@"InsulinDose" inManagedObjectContext:self.managedObjectContext];

    managedInsulinDose.logEntry = self;
    managedInsulinDose.insulinType = insulinType;

    return managedInsulinDose;
}

@end
