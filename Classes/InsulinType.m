//
//  InsulinType.m
//  Glucose
//
//  Created by Brandon Fosdick on 7/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "InsulinType.h"


@implementation InsulinType

@synthesize typeID, shortName;

// Create a new InsulinType record in the database and return an new InsulinType object
+ (InsulinType*)insertNewInsulinTypeIntoDatabase:(sqlite3*)database withName:(NSString*)n;
{
	static char *sql = "INSERT INTO InsulinTypes (sequence, shortName) SELECT MAX(sequence)+1,? FROM InsulinTypes";
	sqlite3_stmt *statement;
	
	if( sqlite3_prepare_v2(database, sql, -1, &statement, NULL) != SQLITE_OK )
		NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
	
	NSString* name;
	if( n && [n length])
		name = [NSString stringWithString:n];
	else
		name = [NSString stringWithString:@"New Insulin Type"];
	
	sqlite3_bind_text(statement, 1, [name UTF8String], -1, SQLITE_TRANSIENT);
    int success = sqlite3_step(statement);
	sqlite3_finalize(statement);
	[name release];
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
		[shortName retain];
	}
    return self;
}

- (void)dealloc
{
	[shortName release];
	[super dealloc];	
}

@end
