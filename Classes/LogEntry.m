//
//  LogEntry.m
//  Glucose
//
//  Created by Brandon Fosdick on 6/28/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "Constants.h"

#import "LogEntry.h"
#import "InsulinDose.h"
#import "InsulinType.h"


// Static variables for compiled SQL queries. This implementation choice is to be able to share a one time
// compilation of each query across all instances of the class. Each time a query is used, variables may be bound
// to it, it will be "stepped", and then reset for the next usage. When the application begins to terminate,
// a class method will be invoked to "finalize" (delete) the compiled queries - this must happen before the database
// can be closed.
static sqlite3_stmt *insert_statement = nil;
static sqlite3_stmt *init_statement = nil;
static sqlite3_stmt *delete_statement = nil;
static sqlite3_stmt *hydrate_statement = nil;
static sqlite3_stmt *flush_statement = nil;

static const char *const flush_sql = "UPDATE localLogEntries SET timestamp=?, glucose=?, glucoseUnits=?, categoryID=?, dose0=?, dose1=?, typeID0=?, typeID1=?, note=? WHERE ID=?";
//static const char *const flush_sql = "UPDATE localLogEntries SET timestamp=datetime(?,'unixepoch'), glucose=?, glucoseUnits=?, categoryID=?, dose0=?, dose1=?, typeID0=?, typeID1=?, note=? WHERE ID=?";
static const char *const init_sql = "SELECT timestamp, glucose, glucoseUnits, categoryID, dose0, dose1, typeID0, typeID1, note FROM localLogEntries WHERE ID=?";

#define	kHeaderString	@"timestamp,glucose,glucoseUnits,category,dose0,type0,dose1,type1,note\n"

@implementation LogEntry

@synthesize entryID, category, dirty;
@synthesize glucose;
@synthesize glucoseUnits;
@synthesize insulin;
@synthesize note;
@synthesize	timestamp;

// Creates a new empty LogEntry record in the database and returns the new entryID
+ (unsigned)insertNewLogEntryIntoDatabase:(sqlite3*)database
{
    if( !insert_statement )
	{
        static char *sql = "INSERT INTO localLogEntries (timestamp) VALUES(strftime('%s',datetime('NOW')))";
        if( sqlite3_prepare_v2(database, sql, -1, &insert_statement, NULL) != SQLITE_OK )
            NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
    }
    int success = sqlite3_step(insert_statement);
    sqlite3_reset(insert_statement);	// Reset instead of finalize so the statement can be reused
    if( success != SQLITE_ERROR )
        return sqlite3_last_insert_rowid(database);

    NSAssert1(0, @"Failed to insert: '%s'.", sqlite3_errmsg(database));
    return -1;
}

+ (void) deleteDosesForInsulinTypeID:(unsigned)typeID fromDatabase:(sqlite3*)database
{
	const char* q0 = "UPDATE localLogEntries SET dose0=NULL, typeID0=NULL WHERE typeID0=?";
	const char* q1 = "UPDATE localLogEntries SET dose1=NULL, typeID1=NULL WHERE typeID1=?";
	sqlite3_stmt* s0;
	sqlite3_stmt* s1;
	
	if( sqlite3_prepare_v2(database, q0, -1, &s0, NULL) == SQLITE_OK )
	{
		sqlite3_bind_int(s0, 1, typeID);
		int success = sqlite3_step(s0);
		sqlite3_finalize(s0);
		if( success != SQLITE_DONE )
			NSAssert1(0, @"Error: failed to delete from database with message '%s'.", sqlite3_errmsg(database));
	}
	if( sqlite3_prepare_v2(database, q1, -1, &s1, NULL) == SQLITE_OK )
	{
		sqlite3_bind_int(s1, 1, typeID);
		int success = sqlite3_step(s1);
		sqlite3_finalize(s1);
		if( success != SQLITE_DONE )
			NSAssert1(0, @"Error: failed to delete from database with message '%s'.", sqlite3_errmsg(database));
	}
}

+ (void) deleteLogEntriesForInsulinTypeID:(unsigned)typeID fromDatabase:(sqlite3*)database
{
	const char *query = "DELETE FROM localLogEntries WHERE typeID0=? OR typeID1=?";
	sqlite3_stmt *statement;
	
	if( sqlite3_prepare_v2(database, query, -1, &statement, NULL) == SQLITE_OK )
	{
		sqlite3_bind_int(statement, 1, typeID);
		sqlite3_bind_int(statement, 2, typeID);
		int success = sqlite3_step(statement);
		sqlite3_finalize(statement);
		if( success != SQLITE_DONE )
			NSAssert1(0, @"Error: failed to delete from database with message '%s'.", sqlite3_errmsg(database));
	}
}

+ (BOOL) moveAllEntriesInCategory:(Category*)src toCategory:(Category*)dest database:(sqlite3*)database;
{
    static const char *const q = "UPDATE localLogEntries SET categoryID=? WHERE categoryID=?";
    sqlite3_stmt *statement;

    if( sqlite3_prepare_v2(database, q, -1, &statement, NULL) != SQLITE_OK )
    {
	NSLog(@"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
	return NO;
    }

    if( src )
	sqlite3_bind_int(statement, 1, src.categoryID);
    if( dest )
	sqlite3_bind_int(statement, 2, dest.categoryID);

    const int result = sqlite3_step(statement);
    sqlite3_finalize(statement);
    if( SQLITE_ERROR == result )
	NSLog(@"Error: failed to move categories with message '%s'.", sqlite3_errmsg(database));
    return result != SQLITE_ERROR;
}

+ (unsigned) numLogEntriesForCategoryID:(unsigned)categoryID database:(sqlite3*)database
{
    const char *const q = "SELECT COUNT() from localLogEntries WHERE categoryID = ?";
    sqlite3_stmt *statement;
    unsigned num = 0;

    if( sqlite3_prepare_v2(database, q, -1, &statement, NULL) == SQLITE_OK )
    {
	sqlite3_bind_int(statement, 1, categoryID);
	unsigned i = 0;
	while( sqlite3_step(statement) == SQLITE_ROW )
	{
	    if( 0 == i )
		num = sqlite3_column_int(statement, 0);
	    ++i;
	}
	if( 0 == i )
	    NSLog(@"No rows returned for COUNT() in numRowsForCategoryID");
	if( i > 1 )
	    NSLog(@"Too many rows returned for COUNT() in numRowsForCategoryID");
	sqlite3_finalize(statement);
    }
    return num;
}

+ (unsigned)numLogEntriesForInsulinTypeID:(unsigned)typeID database:(sqlite3*)database
{
    const char* q = "SELECT COUNT() from localLogEntries WHERE typeID0 = ? OR typeID1 = ?";
    sqlite3_stmt *statement;
    unsigned num = 0;
    
    if( sqlite3_prepare_v2(database, q, -1, &statement, NULL) == SQLITE_OK )
    {
	sqlite3_bind_int(statement, 1, typeID);
	sqlite3_bind_int(statement, 2, typeID);
	unsigned i = 0;
	while( sqlite3_step(statement) == SQLITE_ROW )
	{
	    NSAssert(i==0, @"Too many rows returned for COUNT() in numLogEntriesForInsulinTypeID:");
	    num = sqlite3_column_int(statement, 0);
	    ++i;
	}
	sqlite3_finalize(statement);
    }
    return num;
}

// Finalize (delete) all of the SQLite compiled queries.
+ (void)finalizeStatements
{
    if (insert_statement) sqlite3_finalize(insert_statement);
    if (init_statement) sqlite3_finalize(init_statement);
    if (delete_statement) sqlite3_finalize(delete_statement);
    if (hydrate_statement) sqlite3_finalize(hydrate_statement);
    if (flush_statement) sqlite3_finalize(flush_statement);

    delete_statement = nil;
    flush_statement = nil;
    hydrate_statement = nil;
    init_statement = nil;
    insert_statement = nil;
}

+ (NSData*) createCSV:(sqlite3*)database from:(NSDate*)from to:(NSDate*)to
{
	NSMutableData *data = [NSMutableData dataWithCapacity:2048];
	
	if( !data )
		return nil;
	
	// Fetch the entries for export
	const char* q = "SELECT timestamp,glucose,glucoseUnits,categoryID,dose0,typeID0,dose1,typeID1,note FROM localLogEntries WHERE date(timestamp,'unixepoch','localtime') >= date(?,'unixepoch','localtime') AND date(timestamp,'unixepoch','localtime') <= date(?,'unixepoch','localtime') ORDER BY timestamp ASC";
	sqlite3_stmt *statement;
	unsigned numRows = 0;
	if( sqlite3_prepare_v2(database, q, -1, &statement, NULL) == SQLITE_OK )
	{
		sqlite3_bind_int(statement, 1, [from timeIntervalSince1970]);
		sqlite3_bind_int(statement, 2, [to timeIntervalSince1970]);
		
		// Append the header row
		const char* utfHeader = [kHeaderString UTF8String];
		[data appendBytes:utfHeader length:strlen(utfHeader)];
		
		NSDateFormatter* f = [[NSDateFormatter alloc] init];
		[f setDateStyle:NSDateFormatterMediumStyle];
		[f setTimeStyle:NSDateFormatterMediumStyle];
		const char* s;
		while( sqlite3_step(statement) == SQLITE_ROW )
		{
			const int count = sqlite3_column_count(statement);
			for( unsigned i=0; i < count; ++i )
			{
				if( i )
					[data appendBytes:"," length:strlen(",")];
				switch( i )
				{
					case 0:	//timestamp
					{
						const int a = sqlite3_column_int(statement, i);
						s = [[f stringFromDate:[NSDate dateWithTimeIntervalSince1970:a]] UTF8String];
					}
						break;
					case 2:	// glucoseUnits
					{
						const int a = sqlite3_column_int(statement, i);
						s = a ? "mmol/L" : "mg/dL";
					}
						break;
					case 3:	// categoryID
					{
						const int a = sqlite3_column_int(statement, i);
						Category* c = [appDelegate findCategoryForID:a];
						s = [c.categoryName UTF8String];
					}
						break;
					case 5:	// typeID0
					case 7:	// typeID1
					{
						const int a = sqlite3_column_int(statement, i);
						InsulinType* t = [appDelegate findInsulinTypeForID:a];
						s = [t.shortName UTF8String];
					}
						break;
					default:
						s = (char*)sqlite3_column_text(statement, i);
				}
				
				[data appendBytes:"\"" length:strlen("\"")];
				if( s )
					[data appendBytes:s length:strlen(s)];
				[data appendBytes:"\"" length:strlen("\"")];
			}
			[data appendBytes:"\n" length:strlen("\n")];
			++numRows;
		}
		sqlite3_finalize(statement);
		[f release];
	}
	
	if( numRows )	// Return the data if there was any
		return data;

	// Return nil if now rows were retrieved
	[data release];
	return nil;
}

- (id)init
{
	if( self = [super init] )
    {
		insulin = [[NSMutableArray alloc] init];
	}
    return self;		
}

- (id)initWithID:(unsigned)eid database:(sqlite3 *)db
{
    if( self = [self init] )
    {
		entryID = eid;
	[self load:db];
	}
    return self;
}

- (void)dealloc
{
	[category release];
	[glucose release];
	[insulin release];
	[note release];
	[timestamp release];
	[super dealloc];
}

- (void)deleteFromDatabase:(sqlite3 *)db
{
    // Compile the delete statement if needed.
    if( !delete_statement )
	{
        const char *delete_sql = "DELETE FROM localLogEntries WHERE ID=?";
        if (sqlite3_prepare_v2(db, delete_sql, -1, &delete_statement, NULL) != SQLITE_OK)
            NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(db));
    }

    sqlite3_bind_int(delete_statement, 1, entryID);
    int success = sqlite3_step(delete_statement);
    sqlite3_reset(delete_statement);
    if( success != SQLITE_DONE )
        NSAssert1(0, @"Error: failed to delete from database with message '%s'.", sqlite3_errmsg(db));
}

// Flush the entry to the database if needed
- (void) flush:(sqlite3 *)db
{
	if( !dirty )
		return;

	if( !flush_statement && (sqlite3_prepare_v2(db, flush_sql, -1, &flush_statement, NULL) != SQLITE_OK) )
			NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(db));

	// Set note to nil if it has zero length
	if( note && ![note length] )
		self.note = nil;
	
	sqlite3_bind_int(flush_statement, 1, [timestamp timeIntervalSince1970]);

	if( glucose && ![glucose isEqualToNumber:[NSNumber numberWithInt:0]] )
		sqlite3_bind_double(flush_statement, 2, [glucose doubleValue]);

	const unsigned a = (glucoseUnits == kGlucoseUnits_mgdL) ? 0 : 1;
	sqlite3_bind_int(flush_statement, 3, a);	// glucoseUnits

	if( category )
		sqlite3_bind_int(flush_statement, 4, [self.category categoryID]);

	unsigned i = 0;
	for( InsulinDose* dose in self.insulin )
	{
		if( i >= 2 )	// Limit to two doses for now
			break;

		// Dose and type are stored as a pair. If the pair is incomplete, store neither.
		if( dose.dose && dose.type && ([dose.dose floatValue] != 0) )
		{
			sqlite3_bind_double(flush_statement, 5+i, [dose.dose doubleValue]);
			sqlite3_bind_int(flush_statement, 7+i, [dose.type typeID]);			
			++i;
		}
	}

	if( note && [note length] )
		sqlite3_bind_text(flush_statement, 9, [note UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_int(flush_statement, 10, entryID);

	// Execute the query.
	int success = sqlite3_step(flush_statement);
	sqlite3_reset(flush_statement);		// Reset the query for the next use
	sqlite3_clear_bindings(flush_statement);	//Clear all bindings for next time
	if( success != SQLITE_DONE )
		NSAssert1(0, @"Error: failed to flush with message '%s'.", sqlite3_errmsg(db));
	
	dirty = NO;		// Squeaky clean
}

- (void)load:(sqlite3*)db
{
    if( !init_statement && (sqlite3_prepare_v2(db, init_sql, -1, &init_statement, NULL) != SQLITE_OK) )
	NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(db));

    // For this query, we bind the primary key to the first (and only) placeholder in the statement.
    // Note that the parameters are numbered from 1, not from 0.
    sqlite3_bind_int(init_statement, 1, entryID);

    // Start with a clean insulin array in case this is a reload
    [self.insulin removeAllObjects];

#define ASSIGN_NOT_NULL(_s, _c, _var, _val)		\
if( SQLITE_NULL == sqlite3_column_type(_s, _c) )	\
_var = nil;						\
else							\
_var = _val;

    if( sqlite3_step(init_statement) == SQLITE_ROW )
    {
	ASSIGN_NOT_NULL(init_statement, 0, self.timestamp,
			[NSDate dateWithTimeIntervalSince1970:sqlite3_column_int(init_statement, 0)]);
	ASSIGN_NOT_NULL(init_statement, 1, self.glucose,
			[NSNumber numberWithDouble:sqlite3_column_double(init_statement, 1)]);
	ASSIGN_NOT_NULL(init_statement, 8, self.note,
			[NSString stringWithUTF8String:(const char*)sqlite3_column_text(init_statement, 8)]);

	if( SQLITE_NULL == sqlite3_column_type(init_statement, 2) )
	    self.glucoseUnits = nil;
	else
	{
	    switch(sqlite3_column_int(init_statement, 2))
	    {
		case 0: self.glucoseUnits = kGlucoseUnits_mgdL; break;
		case 1: self.glucoseUnits = kGlucoseUnits_mmolL; break;
		default: self.glucoseUnits = nil; break;
	    }
	}

	if( SQLITE_NULL == sqlite3_column_type(init_statement, 3) )
	    self.category = nil;
	else
	    [self setCategoryWithID:sqlite3_column_int(init_statement, 3)];

	if( (SQLITE_NULL != sqlite3_column_type(init_statement, 4)) &&
	    (SQLITE_NULL != sqlite3_column_type(init_statement, 6)) )
	{
	    [self.insulin addObject:[InsulinDose withType:[appDelegate findInsulinTypeForID:sqlite3_column_int(init_statement, 6)]]];
	    [self setDose:[NSNumber numberWithInt:sqlite3_column_int(init_statement, 4)] insulinDose:[self.insulin lastObject]];
	}
	if( (SQLITE_NULL != sqlite3_column_type(init_statement, 5)) &&
	   (SQLITE_NULL != sqlite3_column_type(init_statement, 7)) )
	{
	    [self.insulin addObject:[InsulinDose withType:[appDelegate findInsulinTypeForID:sqlite3_column_int(init_statement, 7)]]];
	    [self setDose:[NSNumber numberWithInt:sqlite3_column_int(init_statement, 5)] insulinDose:[self.insulin lastObject]];
	}
	// Empty the array if there are no valid doses
	unsigned count = 0;
	for( InsulinDose* d in insulin )
	    if( d.dose )
		++count;
	if( !count )
	    [self.insulin removeAllObjects];
    }
    else
    {
	self.timestamp = nil;
	self.glucose = nil;
	self.category = nil;
    }

    sqlite3_reset(init_statement);	// Reset the statement for future reuse
    dirty = NO;
}

// When entering edit mode setup defaults for any missing fields (like insulin doses)
- (void) setEditing:(BOOL)edit
{
    if( edit )
    {
	// If the insulin array is empty, populate it with the list of default entries from the prefs bundle
	if( ![insulin count] )
	{
	    for( InsulinType* t in appDelegate.defaultInsulinTypes )
		[insulin addObject:[InsulinDose withType:t]];
	    dirty = YES;
	}
    }
    else    // Flush incomplete doses when edit mode ends
    {
	NSMutableIndexSet* indexes = [[NSMutableIndexSet alloc] init];
	unsigned i = 0;
	for( InsulinDose* d in insulin )
	{
	    if( !d.dose || !d.type || ([d.dose floatValue] == 0) )
		[indexes addIndex:i];
	    ++i;
	}
	[insulin removeObjectsAtIndexes:indexes];
    }
}
/*
- (void)dehydrate:(sqlite3 *)db
{
	[self flush:db];

	// Release member variables to reclaim memory. Set to nil to avoid over-releasing them 
    // if dehydrate is called multiple times.

 hydrated = NO;
}
*/

- (void) addDoseWithType:(InsulinType*)t
{
    [insulin addObject:[InsulinDose withType:t]];
}

- (void) removeDoseAtIndex:(unsigned)i
{
    [insulin removeObjectAtIndex:i];
}

#pragma mark -
#pragma mark Properties

- (void) setCategoryWithID:(unsigned)cid
{
	self.category = [appDelegate findCategoryForID:cid];
}

- (void) setCategory:(Category*)c
{
	if( category != c )
	{
		[category release];
		category = c;
		[category retain];
		dirty = YES;
	}
}

- (void) setDose:(NSNumber*)d insulinDose:(InsulinDose*)dose
{
    if( dose && d && ![dose.dose isEqualToNumber:d] )
	{
		dose.dose = d;
		dirty = YES;
	}
}

- (void) setDose:(NSNumber*)d at:(unsigned)index
{
	InsulinDose* dose = [self.insulin objectAtIndex:index];
	[self setDose:d insulinDose:dose];
}

- (void) setDoseType:(InsulinType*)type at:(unsigned)index
{
	InsulinDose* dose = [self.insulin objectAtIndex:index];
	if( dose && type && (dose.type != type) )
	{
		dose.type = type;
		dirty = YES;
	}
}

- (void) setGlucose:(NSNumber*)g
{
    if( g && ((glucose == g) || [glucose isEqualToNumber:g]) )
	return;

	[glucose release];
	glucose = g;
	[glucose retain];
	dirty = YES;
}

- (void) setNote:(NSString*)n
{
    if ((!note && !n) || (note && n && [note isEqualToString:n])) return;
    dirty = YES;
    [note release];
    note = [n copy];	
}

- (void) setTimestamp:(NSDate*)ts
{
	if( timestamp != ts )
	{
		[timestamp release];
		timestamp = ts;
		[timestamp retain];
		dirty = YES;
	}
}

@end
