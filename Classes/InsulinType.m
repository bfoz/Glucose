//
//  InsulinType.m
//  Glucose
//
//  Created by Brandon Fosdick on 7/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "InsulinType.h"

static const char *const sqlInsertUserInsulinType = "INSERT INTO InsulinTypes (typeID, sequence, shortName) SELECT MAX(1000,MAX(typeID)+1),MAX(sequence)+1,? FROM InsulinTypes";

@implementation InsulinType

@synthesize typeID, shortName;

+ (BOOL) insertInsulinType:(InsulinType*)t intoDatabase:(sqlite3*)database
{
    static char *sql = "INSERT INTO InsulinTypes (typeID, sequence, shortName) SELECT ?,MAX(sequence)+1,? FROM InsulinTypes";
    sqlite3_stmt *statement;

    if( sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK )
    {
	NSLog(@"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
	return NO;
    }

    if( !(t.shortName && [t.shortName length]) )
	t.shortName = @"New Insulin Type";

    sqlite3_bind_int(statement, 1, (int)t.typeID);
    sqlite3_bind_text(statement, 2, [t.shortName UTF8String], -1, SQLITE_TRANSIENT);
    int success = sqlite3_step(statement);
    if( SQLITE_ERROR == success )
	NSLog(@"Failed to insert: '%s'.", sqlite3_errmsg(database));
    sqlite3_finalize(statement);
    return success != SQLITE_ERROR;
}

// Create a new InsulinType record in the database and return an new InsulinType object
+ (InsulinType*) newInsulinTypeWithName:(NSString*)n database:(sqlite3*)database
{
	sqlite3_stmt *statement;
	
	if( sqlite3_prepare_v2(database, sqlInsertUserInsulinType, -1, &statement, NULL) != SQLITE_OK )
		NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
	
	NSString* name;
	if( n && [n length])
	name = [NSString stringWithString:n];
	else
	name = @"New Insulin Type";
	
	sqlite3_bind_text(statement, 1, [name UTF8String], -1, SQLITE_TRANSIENT);
    int success = sqlite3_step(statement);
	sqlite3_finalize(statement);
    NSAssert1(success != SQLITE_ERROR, @"Failed to insert: '%s'.", sqlite3_errmsg(database));
	return [[InsulinType alloc] initWithID:sqlite3_last_insert_rowid(database) name:name];
}

// Initialize with a Name and ID
- (id)initWithID:(NSInteger)type name:(NSString*)name
{
    if( self = [super init] )
    {
		typeID = type;
		shortName = name;
	}
    return self;
}

- (void) deleteFromDatabase:(sqlite3*)database
{
	const char *query = "DELETE FROM InsulinTypes WHERE typeID=?";
	sqlite3_stmt *statement;
	
	if( sqlite3_prepare_v2(database, query, -1, &statement, NULL) == SQLITE_OK )
	{
		sqlite3_bind_int(statement, 1, (int)typeID);
		int success = sqlite3_step(statement);
		sqlite3_finalize(statement);
		if( success != SQLITE_DONE )
			NSAssert1(0, @"Error: failed to delete from database with message '%s'.", sqlite3_errmsg(database));
	}
}

- (void) flush:(sqlite3*)database
{
    static const char *sql = "UPDATE InsulinTypes SET shortName=? WHERE typeID=?";
    sqlite3_stmt *statement;
    if( sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK )
    {
	NSLog(@"Error: failed to flush with message '%s'", sqlite3_errmsg(database));
	return;
    }

    sqlite3_bind_text(statement, 1, [self.shortName UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_int(statement, 2, (int)self.typeID);
    if( sqlite3_step(statement) != SQLITE_DONE )
	NSLog(@"Error: failed to flush with message '%s'", sqlite3_errmsg(database));
    sqlite3_finalize(statement);
}

#pragma mark -
#pragma mark Properties

- (void) setShortName:(NSString*)n
{
    if ((!shortName && !n) || (shortName && n && [shortName isEqualToString:n]))
		return;
    shortName = [n copy];	
}

@end
