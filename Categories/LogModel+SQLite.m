#import "LogModel+SQLite.h"

#import "Category.h"
#import "InsulinDose.h"
#import "InsulinType.h"
#import "LogEntry.h"
#import "LogDay.h"

static NSString* bundledDatabaseFilename = @"glucose.sqlite";

@implementation LogModel (SQLite)

+ (NSArray*) loadCategoriesFromDatabase:(sqlite3*)database
{
    const char *const query = "SELECT categoryID, sequence, name FROM LogEntryCategories ORDER BY sequence";
    sqlite3_stmt* statement;

    if( sqlite3_prepare_v2(database, query, -1, &statement, NULL) != SQLITE_OK )
    {
	NSLog(@"loadCategoriesFromDatabase: Failed to prepare statement with message '%s'", sqlite3_errmsg(database));
	return NO;
    }

    NSMutableArray* result = [NSMutableArray array];
    while( sqlite3_step(statement) == SQLITE_ROW )
    {
	const unsigned char *const s = sqlite3_column_text(statement, 2);
	NSString *const name = s ? [NSString stringWithUTF8String:(const char*)s] : @"";
	[result addObject:@{@"name" : name, @"categoryID" : [NSNumber numberWithInt:sqlite3_column_int(statement, 0)], @"sequence" : [NSNumber numberWithInt:sqlite3_column_int(statement, 1)]}];
    }
    sqlite3_finalize(statement);

    return result;
}

+ (NSArray*) loadInsulinTypesFromDatabase:(sqlite3*)database
{
    const char *const query = "SELECT typeID, sequence, shortName FROM InsulinTypes ORDER BY sequence";
    sqlite3_stmt* statement;

    if( sqlite3_prepare_v2(database, query, -1, &statement, NULL) != SQLITE_OK )
    {
	NSLog(@"loadInsulinTypesFromDatabase: Failed to prepare statement with message '%s'", sqlite3_errmsg(database));
	return NO;
    }

    NSMutableArray* types = [NSMutableArray array];
    while( sqlite3_step(statement) == SQLITE_ROW )
    {
	int typeID = sqlite3_column_int(statement, 0);
	const unsigned char *const s = sqlite3_column_text(statement, 2);
	NSString* shortName = s ? [NSString stringWithUTF8String:(const char*)s] : nil;
	[types addObject:@{@"shortName" : shortName, @"insulinTypeID" : [NSNumber numberWithInt:typeID], @"sequence" : [NSNumber numberWithInt:sqlite3_column_int(statement, 1)]}];
    }
    sqlite3_finalize(statement);

    return types;
}

#pragma mark Database paths

+ (NSString*) bundledDatabasePath
{
    return [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:bundledDatabaseFilename];
}

+ (NSString*) writeableSqliteDBPath
{
    NSArray *const paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *const documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:bundledDatabaseFilename];
}

#pragma mark Open and Close

+ (void) closeDatabase:(sqlite3*)database
{
    if( database )
	sqlite3_close(database);
}

+ (sqlite3*) openDatabasePath:(NSString*)path
{
    sqlite3* database = NULL;
    if( sqlite3_open([path UTF8String], &database) != SQLITE_OK )
    {
	// sqlite3_open() doesn't always return a valid connection object on failure
	if( database )
	{
	    sqlite3_close(database);	// Cleanup after failure (release resources)
	    NSLog(@"Failed to open database with message '%s'.", sqlite3_errmsg(database));
	    return NULL;
	}
	else
	    NSLog(@"Failed to allocate a database object for path %@", path);
    }

    return database;
}

@end
