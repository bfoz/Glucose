//
//  LogDay.m
//  Glucose
//
//  Created by Brandon Fosdick on 11/4/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "LogDay.h"

#import "Constants.h"
#import "LogEntry.h"

@interface LogDay ()

@property (nonatomic, strong)	NSString*	units;

- (id) initWithStatement:(sqlite3_stmt*)statement;

- (void) loadUnitsFromDatabase:(sqlite3*)database;

@end


@implementation LogDay

@synthesize	averageGlucose, count;
@synthesize	date;
@synthesize	entries;
@synthesize name;

static const char *sqlLoadDays = "SELECT timestamp, COUNT(timestamp), AVG(glucose) FROM localLogEntries GROUP BY date(timestamp,'unixepoch','localtime') ORDER BY timestamp DESC LIMIT ? OFFSET ?";
static const char *sqlNumDays = "SELECT COUNT() FROM (SELECT DISTINCT date(timestamp,'unixepoch','localtime') FROM localLogEntries)";
static const char*  sqlGlucoseUnits = "SELECT DISTINCT glucoseUnits FROM localLogEntries WHERE date(timestamp,'unixepoch','localtime') = date(?,'unixepoch','localtime') GROUP BY glucoseUnits";

static sqlite3_stmt*	stmtGlucoseUnits = NULL;

// Load a subset of sections given by limit and offset
//  All sections can be loaded by passing limit=-1 and offset=0
+ (unsigned) loadDays:(NSMutableArray*)days fromDatabase:(sqlite3*)database limit:(unsigned)limit offset:(unsigned)offset
{
    unsigned count = 0;
    sqlite3_stmt *statement;

    if( sqlite3_prepare_v2(database, sqlLoadDays, -1, &statement, NULL) != SQLITE_OK )
	return NO;

    NSDateFormatter *const shortDateFormatter = [[NSDateFormatter alloc] init];
    [shortDateFormatter setDateStyle:NSDateFormatterShortStyle];
    sqlite3_bind_int(statement, 1, limit);
    sqlite3_bind_int(statement, 2, offset);
    while( sqlite3_step(statement) == SQLITE_ROW )
    {
	LogDay *const  day = [[LogDay alloc] initWithStatement:statement];
	day.name = [shortDateFormatter stringFromDate:day.date];
	[days addObject:day];
	++count;
    }
    sqlite3_finalize(statement);
    return count;
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
	averageGlucose = 0;
		count = 0;
		entries = [[NSMutableArray alloc] init];
	self.units = NULL;
	}
	return self;
}

- (id) initWithStatement:(sqlite3_stmt*)statement
{
    self = [super init];
    if( self )
    {
	self.date = [NSDate dateWithTimeIntervalSince1970:sqlite3_column_int(statement, 0)];
	count = sqlite3_column_int(statement, 1);
	averageGlucose = sqlite3_column_double(statement, 2);

	entries = [[NSMutableArray alloc] initWithCapacity:count];
	_units = NULL;
	[self loadUnitsFromDatabase:sqlite3_db_handle(statement)];
    }

    return self;
}

// Load the day's units string from the database
- (void) loadUnitsFromDatabase:(sqlite3*)database
{
    // Try to figure out the units string from the entries in the database
    if( !stmtGlucoseUnits )
    {
        if( sqlite3_prepare_v2(database, sqlGlucoseUnits, -1, &stmtGlucoseUnits, NULL) != SQLITE_OK )
	{
            NSLog(@"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
	    return;
	}
    }

    sqlite3_bind_int(stmtGlucoseUnits, 1, [date timeIntervalSince1970]);
    while( sqlite3_step(stmtGlucoseUnits) == SQLITE_ROW )
    {
	/* Use the units from the day's first entry and hope the user hasn't
	 been switching units within a section    */
	_units = [LogEntry unitsStringForInteger:sqlite3_column_int(stmtGlucoseUnits, 0)];
	if( _units )
	    break;
    }
    sqlite3_reset(stmtGlucoseUnits);	// Reset the statement for reuse
}

- (void) deleteAllEntriesFromDatabase:(sqlite3*)database
{
    for( id entry in self.entries )
    {
	[entry deleteFromDatabase:database];
    }
    [self.entries removeAllObjects];
}

- (void) deleteEntry:(LogEntry*)entry fromDatabase:(sqlite3*)database
{
    if( entry && database && [entries containsObject:entry] )
    {
	[entry deleteFromDatabase:database];
	[entries removeObjectIdenticalTo:entry];
	if( count )
	    --count;
	[self updateStatistics];
    }
}

- (void) hydrate:(LogModel*)model database:(sqlite3*)database
{
    entries = [LogEntry logEntriesForLogDay:self model:model database:database];
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

    // Invalidate averageGlucoseString so it can be updated later
    averageGlucoseString = NULL;
}

#pragma mark -
#pragma mark Accessors

- (NSString*) averageGlucoseString
{
    if( averageGlucoseString )
	return averageGlucoseString;

    if( averageGlucose != 0 )
    {
	if( self.units )
	{
//	    const unsigned precision = (units == kGlucoseUnits_mgdL) ? 0 : 1;
//	    averageGlucoseString = [NSString localizedStringWithFormat:@"%.*f%@", precision, averageGlucose, units];
	}
	else
	    averageGlucoseString = [NSString localizedStringWithFormat:@"%.0f", averageGlucose];
    }

    return averageGlucoseString;
}

// Return the units string for the units used by the day's entries
- (NSString*) units
{
    if( _units )
	return _units;

    /*	If the units aren't known, but there's at least one LogEntry available,
	this is probably a new record that wasn't loaded from the database. So,
	use the units from the day's first entry and hope the user hasn't been
	switching units within a day.	*/
    if( [entries count] )
	_units = [[entries objectAtIndex:0] glucoseUnits];

    return _units;
}

@end
