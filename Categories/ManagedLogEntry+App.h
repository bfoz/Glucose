#import "ManagedLogEntry.h"

@class ManagedInsulinDose, ManagedInsulinType;

@interface ManagedLogEntry (App)

+ (ManagedLogEntry*) insertManagedLogEntryInContext:(NSManagedObjectContext*)managedObjectContext;

- (unsigned) glucosePrecision;
- (NSString*) glucoseString;
- (NSString*) glucoseUnitsString;

- (ManagedInsulinDose*) addInsulinDose:(NSNumber*)quantity withInsulinType:(ManagedInsulinType*)insulinType;
- (ManagedInsulinDose*) addDoseWithType:(ManagedInsulinType*)insulinType;

@end
