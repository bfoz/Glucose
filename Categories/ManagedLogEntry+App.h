#import "ManagedLogEntry.h"

@class ManagedInsulinDose, ManagedInsulinType;

@interface ManagedLogEntry (App)

+ (ManagedLogEntry*) insertManagedLogEntryInContext:(NSManagedObjectContext*)managedObjectContext;

- (unsigned) glucosePrecision;
- (NSString*) glucoseString;
- (NSString*) glucoseUnitsString;

- (ManagedInsulinDose*) addDoseWithType:(ManagedInsulinType*)insulinType;

@end
