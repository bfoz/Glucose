#import "ManagedLogEntry.h"

@class ManagedInsulinType;

@interface ManagedLogEntry (App)

+ (ManagedLogEntry*) insertManagedLogEntryInContext:(NSManagedObjectContext*)managedObjectContext;

- (unsigned) glucosePrecision;
- (NSString*) glucoseString;
- (NSString*) glucoseUnitsString;

- (void) addDoseWithType:(ManagedInsulinType*)insulinType;

@end
