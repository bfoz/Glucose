#import "LogModel.h"

@class ManagedInsulinDose;

@interface LogModel (SpecHelper)

- (NSPersistentStoreCoordinator*) persistentStoreCoordinator;

- (ManagedInsulinType*) insertManagedInsulinType;

@end
