//
//  LogDay.m
//  Glucose
//
//  Created by Brandon Fosdick on 11/4/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "LogDay.h"
#import "LogEntry.h"

@implementation LogDay

@synthesize	averageGlucose, count;
@synthesize	date;
@synthesize	entries;
@synthesize name;

- (id) initWithDate:(NSDate*)d
{
	if( self = [super init] )
	{
		self.date = d;
		count = 0;
		entries = [[NSMutableArray alloc] init];
	}
	return self;
}

- (id) initWithDate:(NSDate*)d count:(unsigned)c
{
	if( self = [super init] )
	{
		self.date = d;
		count = c;
		entries = [[NSMutableArray alloc] initWithCapacity:c];
	}
	return self;
}

- (void) hydrate:(sqlite3*)db
{
	const char* q = "SELECT ID FROM localLogEntries WHERE date(timestamp,'unixepoch','localtime') = date(?,'unixepoch','localtime') ORDER BY timestamp DESC";
	sqlite3_stmt *statement;

	if( sqlite3_prepare_v2(db, q, -1, &statement, NULL) == SQLITE_OK )
	{
        sqlite3_bind_int(statement, 1, [date timeIntervalSince1970]);
		averageGlucose = 0;
		unsigned i = 0;
		while( sqlite3_step(statement) == SQLITE_ROW )
		{
			LogEntry *const newEntry = [[LogEntry alloc] initWithID:sqlite3_column_int(statement, 0) database:db];
			[entries addObject:newEntry];
			if( newEntry.glucose )
			{
				averageGlucose += [newEntry.glucose floatValue];
				++i;
			}
		}
		sqlite3_finalize(statement);
		averageGlucose = i ? averageGlucose/i : 0;
	}
}

// May need to sortEntries after calling this
- (void) insertEntry:(LogEntry*)entry atIndex:(unsigned)index
{
	if( entry )
	{
		[entries insertObject:entry atIndex:0];
		++count;
		[self updateStatistics];
	}
}

- (void) removeEntry:(LogEntry*)entry
{
	if( entry && count )
	{
		[entries removeObjectIdenticalTo:entry];
		--count;
		[self updateStatistics];
	}
}

- (void) sortEntries
{
	[entries sortUsingDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES selector:@selector(compare:)]]];
}

- (void) updateStatistics
{
	averageGlucose = 0;
	unsigned i = 0;
	for( LogEntry* entry in entries )
	{
		if( entry.glucose )
		{
			averageGlucose += [entry.glucose floatValue];
			++i;
		}
	}
	averageGlucose = i ? averageGlucose/i : 0;
}

@end
