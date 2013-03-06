#import <CoreData/CoreData.h>

#import "LogModel+CoreData.h"
#import "LogModel+SQLite.h"

#import "ManagedCategory.h"
#import "ManagedInsulinType.h"

#import "Category.h"
#import "InsulinType.h"

@implementation LogModel (CoreData)

+ (NSURL*) applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

+ (NSURL*) sqlitePersistentStoreURL
{
    return [[LogModel applicationDocumentsDirectory] URLByAppendingPathComponent:@"GlucoseCoreData.sqlite"];
}

+ (void) importFromBundledDatabaseIntoContext:(NSManagedObjectContext*)managedObjectContext
{
    sqlite3* database = [LogModel openDatabasePath:[LogModel bundledDatabasePath]];
    if( !database )
	return;

    NSArray* bundledCategories = [LogModel loadCategoriesFromDatabase:database];
    NSArray* bundledInsulinTypes = [LogModel loadInsulinTypesFromDatabase:database];

    [LogModel closeDatabase:database];

    for( NSDictionary* category in bundledCategories )
    {
	ManagedCategory* managedCategory = [LogModel insertManagedCategoryIntoContext:managedObjectContext];
	managedCategory.name = [category objectForKey:@"name"];
	managedCategory.sequenceNumber = [category objectForKey:@"sequence"];
    }

    for( NSDictionary* insulinType in bundledInsulinTypes )
    {
	ManagedInsulinType* managedInsulinType = [LogModel insertManagedInsulinTypeIntoContext:managedObjectContext];
	managedInsulinType.shortName = [insulinType objectForKey:@"shortName"];
	managedInsulinType.sequenceNumber = [[insulinType objectForKey:@"sequence"] intValue];
    }
}

+ (NSManagedObjectContext*) managedObjectContext
{
    NSManagedObjectContext* _managedObjectContext = nil;

    BOOL sqliteDatabaseAlreadyExisted = [[NSFileManager defaultManager] fileExistsAtPath:[[LogModel sqlitePersistentStoreURL] path]];
    NSPersistentStoreCoordinator* coordinator = [self persistentStoreCoordinator];
    if( coordinator )
    {
	_managedObjectContext = [[NSManagedObjectContext alloc] init];
	_managedObjectContext.persistentStoreCoordinator = coordinator;

	if( !sqliteDatabaseAlreadyExisted )
	{
	    NSManagedObjectContext* importContext = [[NSManagedObjectContext alloc] init];
	    importContext.persistentStoreCoordinator = coordinator;
	    importContext.undoManager = nil;    // Disable the undo manager so it doesn't store history that we don't care about

	    [LogModel importFromBundledDatabaseIntoContext:importContext];

	    // Set up the default insulins for new entries if no setting exists
	    NSArray* storedInsulinTypesForNewEntries = [LogModel settingsNewEntryInsulinTypes];
	    if( !storedInsulinTypesForNewEntries.count )
	    {
		[LogModel saveManagedObjectContext:importContext];
		ManagedInsulinType* aspart = [self insertOrIgnoreManagedInsulinTypeShortName:@"Aspart" intoContext:importContext];
		ManagedInsulinType* nph = [self insertOrIgnoreManagedInsulinTypeShortName:@"NPH" intoContext:importContext];
		[LogModel flushInsulinTypesForNewEntries:[NSOrderedSet orderedSetWithArray:@[aspart, nph]]];
	    }

	    NSError* error;
	    if( ![importContext save:&error] )
		NSLog(@"Couldn't save after importing bundled database: %@", [error localizedDescription]);
	}
    }

    return _managedObjectContext;
}

+ (NSManagedObjectModel*) managedObjectModel
{
    return [[NSManagedObjectModel alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"Glucose" withExtension:@"momd"]];
}

+ (NSPersistentStore*) addPersistentStoreURL:(NSURL*)storeURL toCoordinator:(NSPersistentStoreCoordinator*)coordinator options:(NSDictionary*)options error:(NSError**)error
{
#ifdef SPECS
    return [coordinator addPersistentStoreWithType:NSInMemoryStoreType
				     configuration:nil
					       URL:nil
					   options:nil
					     error:error];
#else
    return [coordinator addPersistentStoreWithType:NSSQLiteStoreType
				     configuration:nil
					       URL:storeURL
					   options:options
					     error:error];
#endif
}

+ (NSPersistentStoreCoordinator*) persistentStoreCoordinator
{
    NSError* error = nil;
    NSURL* storeURL = [LogModel sqlitePersistentStoreURL];
    NSPersistentStoreCoordinator* _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if( ![LogModel addPersistentStoreURL:storeURL
			   toCoordinator:_persistentStoreCoordinator
				 options:@{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
				   error:&error] )
    {
        /*
         Replace this implementation with code to handle the error appropriately.

         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.


         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.

         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
	 [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
         */

        NSLog(@"Unresolved error %@", error);
        abort();
    }

    return _persistentStoreCoordinator;
}

+ (void) saveManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    NSError* error = nil;
    if( ![managedObjectContext save:&error] )
    {
	NSLog(@"Failed to save to data store: %@", [error localizedDescription]);
	NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
	if( [detailedErrors count] )
	{
	    for( NSError* detailedError in detailedErrors )
		NSLog(@"  DetailedError: %@", [detailedError userInfo]);
	}
	else
	    NSLog(@"  %@", [error userInfo]);
    }
}

#pragma mark -

+ (NSFetchRequest*) fetchRequestForLogDays
{
    return [NSFetchRequest fetchRequestWithEntityName:@"LogDay"];
}

+ (NSFetchRequest*) fetchRequestForOrderedLogDays
{
    NSFetchRequest* fetchRequest = [self fetchRequestForLogDays];
    fetchRequest.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO]];

    return fetchRequest;
}

+ (NSFetchRequest*) fetchRequestForOrderedCategories
{
    NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Category"];
    fetchRequest.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"sequenceNumber" ascending:YES]];

    return fetchRequest;
}

+ (NSFetchRequest*) fetchRequestForOrderedInsulinTypes
{
    NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"InsulinType"];
    fetchRequest.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"sequenceNumber" ascending:YES]];

    return fetchRequest;
}

+ (ManagedCategory*) insertManagedCategoryIntoContext:(NSManagedObjectContext*)managedObjectContext
{
    return [NSEntityDescription insertNewObjectForEntityForName:@"Category" inManagedObjectContext:managedObjectContext];
}

+ (ManagedInsulinType*) insertManagedInsulinTypeIntoContext:(NSManagedObjectContext*)managedObjectContext
{
    return [NSEntityDescription insertNewObjectForEntityForName:@"InsulinType" inManagedObjectContext:managedObjectContext];
}

+ (ManagedInsulinType*) insertManagedInsulinTypeShortName:(NSString*)name intoContext:(NSManagedObjectContext*)managedObjectContext
{
    ManagedInsulinType* managedInsulinType =  [NSEntityDescription insertNewObjectForEntityForName:@"InsulinType"
									    inManagedObjectContext:managedObjectContext];

    managedInsulinType.shortName = name;

    return managedInsulinType;
}

+ (ManagedInsulinType*) insertOrIgnoreManagedInsulinTypeShortName:(NSString*)name intoContext:(NSManagedObjectContext*)managedObjectContext
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"InsulinType" inManagedObjectContext:managedObjectContext]];
    [fetchRequest setFetchLimit:1];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"shortName == %@", name]];

    NSError* error;
    NSArray* fetchedTips = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if( fetchedTips.count )
	return [fetchedTips objectAtIndex:0];

    return [self insertManagedInsulinTypeShortName:(NSString*)name intoContext:managedObjectContext];
}

@end
