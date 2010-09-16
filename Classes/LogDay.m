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

static const char *sqlLoadDays = "SELECT timestamp, COUNT(timestamp) FROM localLogEntries GROUP BY date(timestamp,'unixepoch','localtime') ORDER BY timestamp DESC LIMIT ? OFFSET ?";
static const char *sqlNumDays = "SELECT COUNT() FROM (SELECT DISTINCT date(timestamp,'unixepoch','localtime') FROM localLogEntries)";

// Load a subset of sections given by limit and offset
//  All sections can be loaded by passing limit=-1 and offset=0
+ (BOOL) loadDays:(NSMutableArray*)days fromDatabase:(sqlite3*)database limit:(unsigned)limit offset:(unsigned)offset
{
    sqlite3_stmt *statement;

    if( sqlite3_prepare_v2(database, sqlLoadDays, -1, &statement, NULL) != SQLITE_OK )
	return NO;

    NSDateFormatter *const shortDateFormatter = [[NSDateFormatter alloc] init];
    [shortDateFormatter setDateStyle:NSDateFormatterShortStyle];
    sqlite3_bind_int(statement, 1, limit);
    sqlite3_bind_int(statement, 2, offset);
    while( sqlite3_step(statement) == SQLITE_ROW )
    {
	NSDate *const date = [NSDate dateWithTimeIntervalSince1970:sqlite3_column_int(statement, 0)];
	LogDay *const  day = [[LogDay alloc] initWithDate:date count:sqlite3_column_int(statement, 1)];
	day.name = [shortDateFormatter stringFromDate:date];
	[days addObject:day];
	[day release];
    }
    sqlite3_finalize(statement);
    [shortDateFormatter release];
    return YES;
}

+ (unsigned) numberOfDays:(sqlite3*)db
{
    sqlite3_stmt *statement;
    unsigned num = 0;

    if( sqlite3_prepare_v2(db, sqlNumDays, -1, &statement, NULL) == SQLITE_OK )
    {
	unsigned i = 0;
	while( sqlite3_step(statement) == SQLITE_ROW )
	{
	    NSAssert(i==0, @"Too many rows returned for COUNT() in numberOfDays:");
	    num = sqlite3_column_int(statement, 0);
	    ++i;
	}
	sqlite3_finalize(statement);
    }
    return num;
}

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

- (void) deleteAllEntriesFromDatabase:(sqlite3*)database
{
    for( id entry in self.entries )
    {
	[entry deleteFromDatabase:database];
    }
    [self.entries removeAllObjects];
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
	    [newEntry release];
		}
		sqlite3_finalize(statement);
		averageGlucose = i ? averageGlucose/i : 0;
	}
}

// Insert a new entry and maintain sort
// NOTE: Assumes entries is already sorted
- (void) insertEntry:(LogEntry*)entry
{
	if( !entry )
		return;

	unsigned i = 0;
	if( count )
	{
		// Find the index that entry should be inserted at
		const double a = [entry.timestamp timeIntervalSince1970];
		for( LogEntry* e in entries )
		{
			if( a > [e.timestamp timeIntervalSince1970] )
				break;
			++i;
		}
	}
	// Put the entry in its place
	[self insertEntry:entry atIndex:i];
}

// May need to sortEntries after calling this
- (void) insertEntry:(LogEntry*)entry atIndex:(unsigned)index
{
	if( entry )
	{
		[entries insertObject:entry atIndex:index];
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
    id descriptor = [NSSortDescriptor sortDescriptorWithKey:@"timestamp"
						  ascending:YES
						   selector:@selector(compare:)];
    [entries sortUsingDescriptors:[NSArray arrayWithObject:descriptor]];
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
