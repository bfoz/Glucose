#import <CoreData/CoreData.h>

#import "LogModel+CoreData.h"
#import "LogModel+SpecHelper.h"

#import "ManagedInsulinType.h"
#import "ManagedLogEntry+App.h"

NSPersistentStoreCoordinator* _persistentStoreCoordinator = nil;

@interface LogModel ()
- (NSManagedObjectModel*) managedObjectModel;
- (NSManagedObjectContext*) managedObjectContext;
@end

@implementation LogModel (SpecHelper)

+ (void) afterEach
{
    NSArray* stores = [_persistentStoreCoordinator persistentStores];

    for( NSPersistentStore* store in stores )
	[_persistentStoreCoordinator removePersistentStore:store error:nil];

    _persistentStoreCoordinator = nil;

    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString* domain = [[NSBundle mainBundle] bundleIdentifier];
    [defaults removePersistentDomainForName:domain];
    for( NSString* key in [defaults persistentDomainForName:domain] )
	[defaults removeObjectForKey:key];
    [NSUserDefaults resetStandardUserDefaults];
}

- (NSPersistentStoreCoordinator*) persistentStoreCoordinator
{
    if( _persistentStoreCoordinator )
        return _persistentStoreCoordinator;

    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if( ![_persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:&error] )
    {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }

    return _persistentStoreCoordinator;
}

#pragma mark Core Data Helpers

- (ManagedInsulinType*) insertManagedInsulinType
{
    return [LogModel insertManagedInsulinTypeIntoContext:self.managedObjectContext];
}

- (ManagedInsulinType*) insertManagedInsulinTypeShortName:(NSString*)name
{
    ManagedInsulinType* managedInsulinType =  [self insertManagedInsulinType];
    managedInsulinType.shortName = name;

    return managedInsulinType;
}

- (ManagedLogDay*) insertManagedLogDay
{
    ManagedLogDay* logDay = [LogModel insertManagedLogDayIntoContext:self.managedObjectContext];
    [(NSMutableArray*)self.logDays addObject:logDay];
    return logDay;
}

@end
