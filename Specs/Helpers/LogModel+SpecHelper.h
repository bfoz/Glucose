#import "LogModel.h"

@class ManagedInsulinDose;

@interface LogModel (SpecHelper)

- (NSPersistentStoreCoordinator*) persistentStoreCoordinator;

- (ManagedInsulinType*) insertManagedInsulinType;
- (ManagedInsulinType*) insertManagedInsulinTypeShortName:(NSString*)name;
- (ManagedLogDay*) insertManagedLogDay;
- (ManagedLogEntry*) insertManagedLogEntryIntoManagedLogDay:(ManagedLogDay*)logDay;

@end
