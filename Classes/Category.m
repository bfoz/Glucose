//
//  Category.m
//  Glucose
//
//  Created by Brandon Fosdick on 7/4/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Category.h"

static const char *const sqlInsertUserCategory = "INSERT INTO LogEntryCategories (categoryID, sequence, name) SELECT MAX(1000,MAX(categoryID)+1),MAX(sequence)+1,? FROM LogEntryCategories";

@implementation Category

@synthesize categoryID, categoryName;

+ (BOOL) deleteCategory:(Category*)c fromDatabase:(sqlite3*)database;
{
    static const char *query = "DELETE FROM LogEntryCategories WHERE categoryID=?";
    sqlite3_stmt *statement;

    if( !c )
	return NO;

    if( sqlite3_prepare_v2(database, query, -1, &statement, NULL) != SQLITE_OK )
    {
	NSLog(@"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
	return NO;
    }

    sqlite3_bind_int(statement, 1, c.categoryID);
    const int result = sqlite3_step(statement);
    sqlite3_finalize(statement);
    if( SQLITE_ERROR == result )
	NSLog(@"Error: failed to delete from database with message '%s'.", sqlite3_errmsg(database));
    return result != SQLITE_ERROR;
}

+ (BOOL) insertCategory:(Category*)c intoDatabase:(sqlite3*)database
{
    static char *sql = "INSERT INTO LogEntryCategories (categoryID, sequence, name) SELECT ?,MAX(sequence)+1,? FROM LogEntryCategories";
    sqlite3_stmt *statement;

    if( sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK )
    {
	NSLog(@"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
	return NO;
    }

    if( !(c.categoryName && [c.categoryName length]) )
	c.categoryName = @"New Category";

    sqlite3_bind_int(statement, 1, c.categoryID);
    sqlite3_bind_text(statement, 2, [c.categoryName UTF8String], -1, SQLITE_TRANSIENT);
    int success = sqlite3_step(statement);
    if( SQLITE_ERROR == success )
	NSLog(@"Failed to insert: '%s'.", sqlite3_errmsg(database));
    sqlite3_finalize(statement);
    return success != SQLITE_ERROR;
}

// Create a new Category record in the database and return an new Category object
+ (Category*) newCategoryWithName:(NSString*)n database:(sqlite3*)database
{
	sqlite3_stmt *statement;
	
    if( sqlite3_prepare_v2(database, sqlInsertUserCategory, -1, &statement, NULL) != SQLITE_OK )
		NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
	
	NSString* name;
	if( n && [n length])
		name = [NSString stringWithString:n];
	else
		name = @"New Category";
	
	sqlite3_bind_text(statement, 1, [name UTF8String], -1, SQLITE_TRANSIENT);
    int success = sqlite3_step(statement);
	sqlite3_finalize(statement);
    NSAssert1(success != SQLITE_ERROR, @"Failed to insert: '%s'.", sqlite3_errmsg(database));
	return [[Category alloc] initWithID:sqlite3_last_insert_rowid(database) name:name];
}

+ (BOOL) loadCategories:(NSMutableArray*)result fromDatabase:(sqlite3*)database
{
    const char *const query = "SELECT categoryID, sequence, name FROM LogEntryCategories ORDER BY sequence";
    sqlite3_stmt* statement;

    if( sqlite3_prepare_v2(database, query, -1, &statement, NULL) != SQLITE_OK )
    {
	NSLog(@"loadCategories: Failed to prepare statement with message '%s'", sqlite3_errmsg(database));
	return NO;
    }

    while( sqlite3_step(statement) == SQLITE_ROW )
    {
	int categoryID = sqlite3_column_int(statement, 0);
	const unsigned char *const s = sqlite3_column_text(statement, 2);
	NSString *const name = s ? [NSString stringWithUTF8String:(const char*)s] : @"";
	Category* category = [[Category alloc] initWithID:categoryID name:name];
	[result addObject:category];
    }
    sqlite3_finalize(statement);

    return YES;
}

- (id)initWithID:(NSInteger)cid name:(NSString*)name;
{
    if( self = [super init] )
    {
		self.categoryID = cid;
		self.categoryName = name;
	}
    return self;
}


- (void) flush:(sqlite3*)database
{
    static const char *sql = "UPDATE LogEntryCategories SET name=? WHERE categoryID=?";
    sqlite3_stmt *statement;
    if( sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK )
    {
	NSLog(@"Error: failed to flush with message '%s'", sqlite3_errmsg(database));
	return;
    }

    sqlite3_bind_text(statement, 1, [self.categoryName UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_int(statement, 2, self.categoryID);
    if( sqlite3_step(statement) != SQLITE_DONE )
	NSLog(@"Error: failed to flush with message '%s'", sqlite3_errmsg(database));
    sqlite3_finalize(statement);
}

#pragma mark -
#pragma mark Properties

- (void) setCategoryName:(NSString*)n
{
    if ((!categoryName && !n) || (categoryName && n && [categoryName isEqualToString:n])) return;
    categoryName = [n copy];	
}

@end
