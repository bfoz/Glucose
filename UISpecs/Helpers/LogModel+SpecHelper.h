#import "LogModel.h"

@class ManagedInsulinDose;

@interface LogModel (SpecHelper)

- (NSPersistentStoreCoordinator*) persistentStoreCoordinator;

- (ManagedInsulinType*) insertManagedInsulinType;
- (ManagedInsulinType*) insertManagedInsulinTypeShortName:(NSString*)name;
- (ManagedLogDay*) insertManagedLogDay;

@end
