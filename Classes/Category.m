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

@end
