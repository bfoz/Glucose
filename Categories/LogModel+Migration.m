#import <CoreData/CoreData.h>

#import "LogModel.h"
#import "LogModel+CoreData.h"
#import "LogModel+Migration.h"
#import "LogModel+SQLite.h"

#import "ManagedCategory.h"
#import "ManagedInsulinDose.h"
#import "ManagedInsulinType.h"
#import "ManagedLogDay+App.h"
#import "ManagedLogEntry+App.h"

#import "Category.h"
#import "InsulinDose.h"
#import "InsulinType.h"
#import "LogEntry.h"

#define	kDefaultGlucoseUnits	@"DefaultGlucoseUnits"
#define	kDefaultInsulinTypes	@"DefaultInsulinTypes"

@interface LogModel ()
- (NSManagedObjectContext*) managedObjectContext;
@end

@implementation LogModel (Migration)

+ (NSString*) backupPath
{
    return [[[LogModel writeableSqliteDBPath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"glucose_backup_of_migrated_original.sqlite"];
}

+ (void) migrateTheDatabase
{
    // If the file exists, but can't be opened by Core Data, then it must need to be migrated

    sqlite3* originalDatabase = [LogModel openDatabasePath:[LogModel writeableSqliteDBPath]];

    NSManagedObjectContext* importContext = [self managedObjectContext];

    [LogModel migrateDatabase:originalDatabase toContext:importContext];

    [LogModel saveManagedObjectContext:importContext];

    [LogModel closeDatabase:originalDatabase];

    // Move the original database file to the backup location
    NSString* backupPath = [self backupPath];
    NSError* error = nil;
    [[NSFileManager defaultManager] moveItemAtPath:[LogModel writeableSqliteDBPath]
					    toPath:backupPath error:&error];
}

+ (BOOL) needsMigration
{
    NSFileManager* fileManager = [NSFileManager defaultManager];

    // If the orignal sqlite DB file doesn't exist, assume that it's already been migrated
    NSString* originalPath = [LogModel writeableSqliteDBPath];
    if( ![fileManager fileExistsAtPath:originalPath] )
	return NO;

    // If a database file does exist, but a backup also exists, assume that migration has already happend
    NSString* backupPath = [[originalPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"glucose_backup_of_migrated_original.sqlite"];
    if( [fileManager fileExistsAtPath:backupPath] )
	return NO;

    return YES;
}

#pragma mark -

+ (NSArray*) migrateCategoriesFromDatabase:(sqlite3*)database toContext:(NSManagedObjectContext*)managedObjectContext
{
    const char *const query = "SELECT categoryID, sequence, name FROM LogEntryCategories ORDER BY sequence";
    sqlite3_stmt* statement;

    if( sqlite3_prepare_v2(database, query, -1, &statement, NULL) != SQLITE_OK )
    {
	NSLog(@"migrateCategoriesFromDatabase: Failed to prepare statement with message '%s'", sqlite3_errmsg(database));
	return nil;
    }

    NSMutableArray* categories = [NSMutableArray array];
    while( sqlite3_step(statement) == SQLITE_ROW )
    {
	const unsigned int categoryID = sqlite3_column_int(statement, 0);
	const unsigned char *const s = sqlite3_column_text(statement, 2);
	NSString *const name = s ? [NSString stringWithUTF8String:(const char*)s] : @"";

	ManagedCategory* managedCategory = [self insertOrIgnoreManagedCategoryName:name inContext:managedObjectContext];

	if( SQLITE_NULL != sqlite3_column_type(statement, 1) )
	    managedCategory.sequenceNumber = sqlite3_column_int(statement, 1);

	[categories addObject:@{@"categoryID" : [NSNumber numberWithInt:categoryID], @"managedObject" : managedCategory}];
    }
    sqlite3_finalize(statement);

    return categories;
}

+ (NSArray*) migrateInsulinTypesFromDatabase:(sqlite3*)database toContext:(NSManagedObjectContext*)managedObjectContext
{
    const char *const query = "SELECT typeID, sequence, shortName FROM InsulinTypes ORDER BY sequence";
    sqlite3_stmt* statement;

    if( sqlite3_prepare_v2(database, query, -1, &statement, NULL) != SQLITE_OK )
    {
	NSLog(@"migrateInsulinTypesFromDatabase: Failed to prepare statement with message '%s'", sqlite3_errmsg(database));
	return nil;
    }

    NSMutableArray* insulinTypes = [NSMutableArray array];
    while( sqlite3_step(statement) == SQLITE_ROW )
    {
	int typeID = sqlite3_column_int(statement, 0);
	const unsigned char *const s = sqlite3_column_text(statement, 2);
	NSString* shortName = s ? [NSString stringWithUTF8String:(const char*)s] : nil;

	ManagedInsulinType* managedInsulinType = [self insertOrIgnoreManagedInsulinTypeShortName:shortName intoContext:managedObjectContext];

	if( SQLITE_NULL != sqlite3_column_type(statement, 1) )
	    managedInsulinType.sequenceNumber = sqlite3_column_int(statement, 1);

	[insulinTypes addObject:@{@"insulinTypeID" : [NSNumber numberWithInt:typeID], @"managedObject" : managedInsulinType}];
    }
    sqlite3_finalize(statement);

    return insulinTypes;
}

+ (NSArray*) migrateLogDaysFromDatabase:(sqlite3*)database toContext:(NSManagedObjectContext*)managedObjectContext
{
    const char *sqlLoadDays = "SELECT timestamp, COUNT(timestamp), AVG(glucose) FROM localLogEntries GROUP BY date(timestamp,'unixepoch','localtime') ORDER BY timestamp DESC";
    sqlite3_stmt* statement;

    if( sqlite3_prepare_v2(database, sqlLoadDays, -1, &statement, NULL) != SQLITE_OK )
    {
	NSLog(@"migrateLogDaysFromDatabase =======> %s", sqlite3_errmsg(database));
	return nil;
    }

    NSMutableArray* logDays = [NSMutableArray array];
    while( sqlite3_step(statement) == SQLITE_ROW )
    {
	NSDate* date = [NSDate dateWithTimeIntervalSince1970:sqlite3_column_int(statement, 0)];
	ManagedLogDay* managedLogDay = [LogModel insertManagedLogDayIntoContext:managedObjectContext];
	managedLogDay.date = date;
	[logDays addObject:managedLogDay];
    }
    sqlite3_finalize(statement);

    return logDays;
}

#define	kAllColumns	    "ID,timestamp,glucose,glucoseUnits,categoryID,dose0,dose1,typeID0,typeID1,note"
#define	kLocalLogEntryTable "localLogEntries"

#define ASSIGN_NOT_NULL(_s, _c, _var, _val)		\
if( SQLITE_NULL == sqlite3_column_type(_s, _c) )	\
_var = nil;						\
else							\
_var = _val;

+ (void) migrateLogEntriesFromDatabase:(sqlite3*)database forLogDay:(ManagedLogDay*)logDay categories:(NSArray*)categories insulinTypes:(NSArray*)insulinTypes toContext:(NSManagedObjectContext*)managedObjectContext
{
    static const char *const sqlLoadLogDay = "SELECT " kAllColumns " FROM " kLocalLogEntryTable " WHERE date(timestamp,'unixepoch','localtime') = date(?,'unixepoch','localtime') ORDER BY timestamp DESC";
    sqlite3_stmt* statement;

    if( sqlite3_prepare_v2(database, sqlLoadLogDay, -1, &statement, NULL) != SQLITE_OK )
    {
	NSLog(@"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
	return;
    }

    sqlite3_bind_int(statement, 1, [logDay.date timeIntervalSince1970]);

    while( sqlite3_step(statement) == SQLITE_ROW )
    {
	ManagedLogEntry* managedLogEntry = [NSEntityDescription insertNewObjectForEntityForName:@"LogEntry"
									 inManagedObjectContext:managedObjectContext];
	managedLogEntry.logDay = logDay;

	ASSIGN_NOT_NULL(statement, 1, managedLogEntry.timestamp,
			[NSDate dateWithTimeIntervalSince1970:sqlite3_column_int(statement, 1)]);
	ASSIGN_NOT_NULL(statement, 2, managedLogEntry.glucose,
			[NSNumber numberWithDouble:sqlite3_column_double(statement, 2)]);
	ASSIGN_NOT_NULL(statement, 9, managedLogEntry.note,
			[NSString stringWithUTF8String:(const char*)sqlite3_column_text(statement, 9)]);

	if( SQLITE_NULL != sqlite3_column_type(statement, 3) )
	{
	    int units = sqlite3_column_int(statement, 3);
	    if( 0 == units )
		managedLogEntry.glucoseUnits = [NSNumber numberWithInt:kGlucoseUnits_mgdL];
	    else if( 1 == units )
		managedLogEntry.glucoseUnits = [NSNumber numberWithInt:kGlucoseUnits_mmolL];
	}

	if( SQLITE_NULL != sqlite3_column_type(statement, 4) )
	    managedLogEntry.category = [self managedCategoryForCategoryID:sqlite3_column_int(statement, 4) inCategories:categories];

	if( (SQLITE_NULL != sqlite3_column_type(statement, 5)) &&
	    (SQLITE_NULL != sqlite3_column_type(statement, 7)) )
	{
	    ManagedInsulinDose* insulinDose = [managedLogEntry addDoseWithType:[self managedInsulinTypeForInsulinTypeID:[NSNumber numberWithInt:sqlite3_column_int(statement, 7)] inInsulinTypes:insulinTypes]];
	    insulinDose.dose = [NSNumber numberWithInt:sqlite3_column_int(statement, 5)];
	}
	if( (SQLITE_NULL != sqlite3_column_type(statement, 6)) &&
	    (SQLITE_NULL != sqlite3_column_type(statement, 8)) )
	{
	    ManagedInsulinDose* insulinDose = [managedLogEntry addDoseWithType:[self managedInsulinTypeForInsulinTypeID:[NSNumber numberWithInt:sqlite3_column_int(statement, 8)] inInsulinTypes:insulinTypes]];
	    insulinDose.dose = [NSNumber numberWithInt:sqlite3_column_int(statement, 6)];
	}
    }

    sqlite3_clear_bindings(statement);
    sqlite3_reset(statement);
}

+ (void) migrateDatabase:(sqlite3*)database toContext:(NSManagedObjectContext*)managedObjectContext
{
    NSArray* categories = [self migrateCategoriesFromDatabase:database toContext:managedObjectContext];
    NSArray* insulinTypes = [self migrateInsulinTypesFromDatabase:database toContext:managedObjectContext];

    NSArray* logDays = [self migrateLogDaysFromDatabase:database toContext:managedObjectContext];

    for( ManagedLogDay* managedLogDay in logDays )
    {
	[self migrateLogEntriesFromDatabase:database
				  forLogDay:managedLogDay
				 categories:categories
			       insulinTypes:insulinTypes
				  toContext:managedObjectContext];
	[managedLogDay updateStatistics];
    }

    // Insulins for new entries
    NSArray* insulinTypeIDs = [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultInsulinTypes];

    NSMutableOrderedSet* managedInsulinTypes = [NSMutableOrderedSet orderedSet];
    for( NSNumber* insulinTypeID in insulinTypeIDs )
    {
	ManagedInsulinType* insulinType = [self managedInsulinTypeForInsulinTypeID:insulinTypeID inInsulinTypes:insulinTypes];
	if( insulinType )
	    [managedInsulinTypes addObject:insulinType];
    }
    [managedObjectContext obtainPermanentIDsForObjects:[managedInsulinTypes array] error:nil];
    [LogModel flushInsulinTypesForNewEntries:managedInsulinTypes];
}

#pragma mark -

+ (ManagedCategory*) managedCategoryForCategoryID:(int)categoryID inCategories:(NSArray*)categories
{
    NSNumber* categoryIDNumber = [NSNumber numberWithInt:categoryID];
    for( NSDictionary* category in categories )
	if( [[category objectForKey:@"categoryID"] isEqualToNumber:categoryIDNumber] )
	    return [category objectForKey:@"managedObject"];
    return nil;
}

+ (ManagedInsulinType*) managedInsulinTypeForInsulinTypeID:(NSNumber*)insulinTypeID inInsulinTypes:(NSArray*)insulinTypes
{
    for( NSDictionary* insulinType in insulinTypes )
	if( [[insulinType objectForKey:@"insulinTypeID"] isEqualToNumber:insulinTypeID] )
	    return [insulinType objectForKey:@"managedObject"];
    return nil;
}

#pragma mark -

+ (ManagedCategory*) insertManagedCategoryName:(NSString*)name inContext:(NSManagedObjectContext*)managedObjectContext
{
    ManagedCategory* managedCategory =  [NSEntityDescription insertNewObjectForEntityForName:@"Category"
								      inManagedObjectContext:managedObjectContext];

    managedCategory.name = name;

    return managedCategory;
}

+ (ManagedCategory*) insertOrIgnoreManagedCategoryName:(NSString*)name inContext:(NSManagedObjectContext*)managedObjectContext
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Category" inManagedObjectContext:managedObjectContext]];
    [fetchRequest setFetchLimit:1];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"name == %@", name]];

    NSError* error;
    NSArray* fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if( fetchedObjects.count )
	return [fetchedObjects objectAtIndex:0];

    return [self insertManagedCategoryName:name inContext:managedObjectContext];
}

@end
