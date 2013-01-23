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

static UIProgressView* __progressView = nil;
static float progress = 0;
static float totalProgress = 1;

@interface LogModel ()
- (NSManagedObjectContext*) managedObjectContext;
@end

@implementation LogModel (Migration)

+ (NSString*) backupPath
{
    return [[[LogModel writeableSqliteDBPath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"glucose_backup_of_migrated_original.sqlite"];
}

void progressTick()
{
    ++progress;
    dispatch_async(dispatch_get_main_queue(), ^{
	[__progressView setProgress:(progress/totalProgress) animated:NO];
    });
}

+ (NSDictionary*) migrateTheDatabaseWithProgressView:(UIProgressView*)progressView
{
    __progressView = progressView;

    // If the file exists, but can't be opened by Core Data, then it must need to be migrated

    sqlite3* originalDatabase = [LogModel openDatabasePath:[LogModel writeableSqliteDBPath]];

    int numberOfCategories = numberOfCategoriesInDatabase(originalDatabase);
    int numberOfInsulinTypes = numberOfInsulinTypesInDatabase(originalDatabase);
    int numberOfLogDays = numberOfLogDaysInDatabase(originalDatabase);
    int numberOfLogEntries = numerOfLogEntriesInDatabase(originalDatabase);
    totalProgress = numberOfCategories + numberOfInsulinTypes + numberOfLogDays + numberOfLogEntries;

    NSManagedObjectContext* importContext = [self managedObjectContext];

    [LogModel migrateDatabase:originalDatabase toContext:importContext];

    [LogModel saveManagedObjectContext:importContext];

    [LogModel closeDatabase:originalDatabase];

    // Move the original database file to the backup location
    NSString* backupPath = [self backupPath];
    NSError* error = nil;
    [[NSFileManager defaultManager] moveItemAtPath:[LogModel writeableSqliteDBPath]
					    toPath:backupPath error:&error];

    return @{ @"numberOfCategories" : [NSNumber numberWithInt:numberOfCategories],
	      @"numberOfInsulinTypes" : [NSNumber numberWithInt:numberOfInsulinTypes],
	      @"numberOfLogDays" : [NSNumber numberWithInt:numberOfLogDays],
	      @"numberOfLogEntries" : [NSNumber numberWithInt:numberOfLogEntries],
	    };
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

int countForQuery(sqlite3* database, const char* query)
{
    sqlite3_stmt* statement;
    int count = 0;

    if( sqlite3_prepare_v2(database, query, -1, &statement, NULL) == SQLITE_OK )
    {
	while( sqlite3_step(statement) == SQLITE_ROW )
	    count = sqlite3_column_int(statement, 0);
    }

    sqlite3_finalize(statement);

    return count;
}

int numberOfCategoriesInDatabase(sqlite3* database)
{
    const char *const query = "SELECT COUNT() FROM LogEntryCategories";
    return countForQuery(database, query);
}

int numberOfInsulinTypesInDatabase(sqlite3* database)
{
    const char *const query = "SELECT COUNT() FROM InsulinTypes";
    return countForQuery(database, query);
}

int numberOfLogDaysInDatabase(sqlite3* database)
{
    return countForQuery(database, "SELECT COUNT() FROM (SELECT DISTINCT date(timestamp,'unixepoch','localtime') FROM localLogEntries)");
}

int numerOfLogEntriesInDatabase(sqlite3* database)
{
    return countForQuery(database, "SELECT COUNT() from localLogEntries");
}

#pragma mark -

+ (NSDictionary*) migrateCategoriesFromDatabase:(sqlite3*)database toContext:(NSManagedObjectContext*)managedObjectContext
{
    const char *const query = "SELECT categoryID, sequence, name FROM LogEntryCategories ORDER BY sequence";
    sqlite3_stmt* statement;

    if( sqlite3_prepare_v2(database, query, -1, &statement, NULL) != SQLITE_OK )
    {
	NSLog(@"migrateCategoriesFromDatabase: Failed to prepare statement with message '%s'", sqlite3_errmsg(database));
	return nil;
    }

    NSMutableDictionary* categories = [NSMutableDictionary dictionary];
    while( sqlite3_step(statement) == SQLITE_ROW )
    {
	const unsigned int categoryID = sqlite3_column_int(statement, 0);
	const unsigned char *const s = sqlite3_column_text(statement, 2);
	NSString *const name = s ? [NSString stringWithUTF8String:(const char*)s] : @"";

	ManagedCategory* managedCategory = [self insertOrIgnoreManagedCategoryName:name inContext:managedObjectContext];

	if( SQLITE_NULL != sqlite3_column_type(statement, 1) )
	    managedCategory.sequenceNumber = sqlite3_column_int(statement, 1);

	[categories setObject:managedCategory forKey:[NSNumber numberWithInt:categoryID]];

	progressTick();
    }
    sqlite3_finalize(statement);

    return categories;
}

+ (NSDictionary*) migrateInsulinTypesFromDatabase:(sqlite3*)database toContext:(NSManagedObjectContext*)managedObjectContext
{
    const char *const query = "SELECT typeID, sequence, shortName FROM InsulinTypes ORDER BY sequence";
    sqlite3_stmt* statement;

    if( sqlite3_prepare_v2(database, query, -1, &statement, NULL) != SQLITE_OK )
    {
	NSLog(@"migrateInsulinTypesFromDatabase: Failed to prepare statement with message '%s'", sqlite3_errmsg(database));
	return nil;
    }

    NSMutableDictionary* insulinTypes = [NSMutableDictionary dictionary];
    while( sqlite3_step(statement) == SQLITE_ROW )
    {
	int typeID = sqlite3_column_int(statement, 0);
	const unsigned char *const s = sqlite3_column_text(statement, 2);
	NSString* shortName = s ? [NSString stringWithUTF8String:(const char*)s] : nil;

	ManagedInsulinType* managedInsulinType = [self insertOrIgnoreManagedInsulinTypeShortName:shortName intoContext:managedObjectContext];

	if( SQLITE_NULL != sqlite3_column_type(statement, 1) )
	    managedInsulinType.sequenceNumber = sqlite3_column_int(statement, 1);

	[insulinTypes setObject:managedInsulinType forKey:[NSNumber numberWithInt:typeID]];

	progressTick();
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

	progressTick();
    }
    sqlite3_finalize(statement);

    return logDays;
}

static const unsigned DATE_COMPONENTS_FOR_DAY = (NSYearCalendarUnit |
						 NSMonthCalendarUnit |
						 NSDayCalendarUnit);

ManagedLogDay* logDayForDate(NSDate* date, NSArray* logDays, NSArray* logDayDateComponents, NSCalendar* calendar)
{
    NSDateComponents *const _date = [calendar components:DATE_COMPONENTS_FOR_DAY
					        fromDate:date];

    unsigned i = 0;
    for( NSDateComponents* dateComponents in logDayDateComponents )
    {
	if( (_date.day == dateComponents.day) && (_date.month == dateComponents.month) && (_date.year == dateComponents.year) )
	    return [logDays objectAtIndex:i];
	++i;
    }

    return nil;
}

#define	kAllColumns	    "ID,timestamp,glucose,glucoseUnits,categoryID,dose0,dose1,typeID0,typeID1,note"

#define ASSIGN_NOT_NULL(_s, _c, _var, _val)		\
if( SQLITE_NULL != sqlite3_column_type(_s, _c) )	\
_var = _val;

+ (void) migrateLogEntriesFromDatabase:(sqlite3*)database logDays:(NSArray*)logDays categories:(NSDictionary*)categories insulinTypes:(NSDictionary*)insulinTypes toContext:(NSManagedObjectContext*)managedObjectContext
{
    const char* sqlLoadLogDay = "SELECT " kAllColumns " FROM localLogEntries ORDER BY timestamp DESC";
    sqlite3_stmt* statement = nil;

    if( sqlite3_prepare_v2(database, sqlLoadLogDay, -1, &statement, NULL) != SQLITE_OK )
    {
	NSLog(@"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
	return;
    }

    NSCalendar *const calendar = [NSCalendar currentCalendar];

    NSMutableArray* logDayDateComponents = [NSMutableArray array];
    for( ManagedLogDay* logDay in logDays )
	[logDayDateComponents addObject:[calendar components:DATE_COMPONENTS_FOR_DAY fromDate:logDay.date]];

    while( sqlite3_step(statement) == SQLITE_ROW )
    {
	ManagedLogEntry* managedLogEntry = [NSEntityDescription insertNewObjectForEntityForName:@"LogEntry"
									 inManagedObjectContext:managedObjectContext];
	ASSIGN_NOT_NULL(statement, 1, managedLogEntry.timestamp,
			[NSDate dateWithTimeIntervalSince1970:sqlite3_column_int(statement, 1)]);
	ASSIGN_NOT_NULL(statement, 2, managedLogEntry.glucose,
			[NSNumber numberWithDouble:sqlite3_column_double(statement, 2)]);
	ASSIGN_NOT_NULL(statement, 4, managedLogEntry.category,
			[categories objectForKey:[NSNumber numberWithInt:sqlite3_column_int(statement, 4)]]);
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

	if( (SQLITE_NULL != sqlite3_column_type(statement, 5)) &&
	    (SQLITE_NULL != sqlite3_column_type(statement, 7)) )
	{
	    ManagedInsulinDose* insulinDose = [managedLogEntry addDoseWithType:[insulinTypes objectForKey:[NSNumber numberWithInt:sqlite3_column_int(statement, 7)]]];
	    insulinDose.dose = [NSNumber numberWithInt:sqlite3_column_int(statement, 5)];
	}
	if( (SQLITE_NULL != sqlite3_column_type(statement, 6)) &&
	    (SQLITE_NULL != sqlite3_column_type(statement, 8)) )
	{
	    ManagedInsulinDose* insulinDose = [managedLogEntry addDoseWithType:[insulinTypes objectForKey:[NSNumber numberWithInt:sqlite3_column_int(statement, 8)]]];
	    insulinDose.dose = [NSNumber numberWithInt:sqlite3_column_int(statement, 6)];
	}

	ManagedLogDay* managedLogDay = logDayForDate(managedLogEntry.timestamp, logDays, logDayDateComponents, calendar);
	if( !managedLogDay )
	{
	    managedLogDay = [LogModel insertManagedLogDayIntoContext:managedObjectContext];
	    managedLogDay.date = managedLogEntry.timestamp;
	}
	managedLogEntry.logDay = managedLogDay;

	progressTick();
    }

    sqlite3_clear_bindings(statement);
    sqlite3_reset(statement);
}

+ (void) migrateDatabase:(sqlite3*)database toContext:(NSManagedObjectContext*)managedObjectContext
{
    NSDictionary* categories = [self migrateCategoriesFromDatabase:database toContext:managedObjectContext];
    NSDictionary* insulinTypes = [self migrateInsulinTypesFromDatabase:database toContext:managedObjectContext];

    NSArray* logDays = [self migrateLogDaysFromDatabase:database toContext:managedObjectContext];

    [self migrateLogEntriesFromDatabase:database
				logDays:logDays
			     categories:categories
			   insulinTypes:insulinTypes
			      toContext:managedObjectContext];

    for( ManagedLogDay* managedLogDay in logDays )
	[managedLogDay updateStatistics];

    // Insulins for new entries
    NSArray* insulinTypeIDs = [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultInsulinTypes];

    NSMutableOrderedSet* managedInsulinTypes = [NSMutableOrderedSet orderedSet];
    for( NSNumber* insulinTypeID in insulinTypeIDs )
    {
	ManagedInsulinType* insulinType = [insulinTypes objectForKey:insulinTypeID];
	if( insulinType )
	    [managedInsulinTypes addObject:insulinType];
    }
    [managedObjectContext obtainPermanentIDsForObjects:[managedInsulinTypes array] error:nil];
    [LogModel flushInsulinTypesForNewEntries:managedInsulinTypes];

    // Migrate the glucose units setting
    NSString* glucoseSetting = [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultGlucoseUnits];
    if( glucoseSetting )
    {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:kDefaultGlucoseUnits];
	if( [glucoseSetting isEqualToString:@" mg/dL"] )
	    [LogModel setGlucoseUnitsSetting:kGlucoseUnits_mgdL];
	else
	    [LogModel setGlucoseUnitsSetting:kGlucoseUnits_mmolL];
    }
}

#pragma mark - Core Data

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
