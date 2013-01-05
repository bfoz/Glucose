#import "LogModel+SQLite.h"

#import "Category.h"
#import "InsulinType.h"

#define	LOG_SQL		@"glucose.sqlite"

@implementation LogModel (SQLite)

+ (NSMutableArray*) loadCategoriesFromDatabase:(sqlite3*)database
{
    const char *const query = "SELECT categoryID, sequence, name FROM LogEntryCategories ORDER BY sequence";
    sqlite3_stmt* statement;

    if( sqlite3_prepare_v2(database, query, -1, &statement, NULL) != SQLITE_OK )
    {
	NSLog(@"loadCategories: Failed to prepare statement with message '%s'", sqlite3_errmsg(database));
	return NO;
    }

    NSMutableArray* result = [NSMutableArray array];
    while( sqlite3_step(statement) == SQLITE_ROW )
    {
	const unsigned char *const s = sqlite3_column_text(statement, 2);
	NSString *const name = s ? [NSString stringWithUTF8String:(const char*)s] : @"";
	Category* category = [[Category alloc] initWithID:sqlite3_column_int(statement, 0)
						     name:name];
	[result addObject:category];
    }
    sqlite3_finalize(statement);

    return result;
}

+ (NSMutableArray*) loadInsulinTypesFromDatabase:(sqlite3*)database
{
    const char *const query = "SELECT typeID, sequence, shortName FROM InsulinTypes ORDER BY sequence";
    sqlite3_stmt* statement;

    if( sqlite3_prepare_v2(database, query, -1, &statement, NULL) != SQLITE_OK )
    {
	NSLog(@"loadInsulinTypes: Failed to prepare statement with message '%s'", sqlite3_errmsg(database));
	return NO;
    }

    NSMutableArray* types = [NSMutableArray array];
    while( sqlite3_step(statement) == SQLITE_ROW )
    {
	int typeID = sqlite3_column_int(statement, 0);
	const unsigned char *const s = sqlite3_column_text(statement, 2);
	NSString* shortName = s ? [NSString stringWithUTF8String:(const char*)s] : nil;
	InsulinType* type = [[InsulinType alloc] initWithID:typeID name:shortName];
	[types addObject:type];
    }
    sqlite3_finalize(statement);

    return types;
}

+ (NSString*) bundledDatabasePath
{
    return [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:LOG_SQL];
}

+ (NSString*) writeableSqliteDBPath
{
    NSArray *const paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *const documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:LOG_SQL];
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
