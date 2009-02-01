//
//  Category.m
//  Glucose
//
//  Created by Brandon Fosdick on 7/4/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Category.h"


@implementation Category

@synthesize categoryID, categoryName;

// Create a new Category record in the database and return an new Category object
+ (Category*)insertNewCategoryIntoDatabase:(sqlite3*)database withName:(NSString*)n
{
	static char *sql = "INSERT INTO LogEntryCategories (sequence, name) SELECT MAX(sequence)+1,? FROM LogEntryCategories";
	sqlite3_stmt *statement;
	
	if( sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK )
		NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
	
	NSString* name;
	if( n && [n length])
		name = [NSString stringWithString:n];
	else
		name = [NSString stringWithString:@"New Category"];
	
	sqlite3_bind_text(statement, 1, [name UTF8String], -1, SQLITE_TRANSIENT);
    int success = sqlite3_step(statement);
	sqlite3_finalize(statement);
	[name release];
    NSAssert1(success != SQLITE_ERROR, @"Failed to insert: '%s'.", sqlite3_errmsg(database));
	return [[Category alloc] initWithID:sqlite3_last_insert_rowid(database) name:name];
}

+ (unsigned)numRowsForCategoryID:(unsigned)cid database:(sqlite3*)database
{
    const char* q = "SELECT COUNT() from localLogEntries WHERE categoryID = ?";
    sqlite3_stmt *statement;
    unsigned num = 0;
    
    if( sqlite3_prepare_v2(database, q, -1, &statement, NULL) == SQLITE_OK )
    {
	sqlite3_bind_int(statement, 1, cid);
	unsigned i = 0;
	while( sqlite3_step(statement) == SQLITE_ROW )
	{
	    NSAssert(i==0, @"Too many rows returned for COUNT() in numRowsForCategoryID:");
	    num = sqlite3_column_int(statement, 0);
	    ++i;
	}
	sqlite3_finalize(statement);
    }
    return num;
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

- (void)dealloc
{
	[categoryName release];
	[super dealloc];
}

#pragma mark -
#pragma mark Properties

- (void) setCategoryName:(NSString*)n
{
    if ((!categoryName && !n) || (categoryName && n && [categoryName isEqualToString:n])) return;
    [categoryName release];
    categoryName = [n copy];	
}

@end
