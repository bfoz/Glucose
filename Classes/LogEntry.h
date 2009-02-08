//
//  LogEntry.h
//  Glucose
//
//  Created by Brandon Fosdick on 6/28/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

#import "Category.h"

@class InsulinDose;
@class InsulinType;

@interface LogEntry : NSObject
{
	unsigned	entryID;
	Category*	category;
    NSNumber*	glucose;
	NSString*	glucoseUnits;
	NSMutableArray*	insulin;
    NSString*	note;
    NSDate*		timestamp;
    BOOL	dirty;
	BOOL	hydrated;
}

@property (nonatomic, readonly)	unsigned	entryID;
@property (nonatomic, retain)	Category*	category;
@property (nonatomic, readonly)	BOOL		dirty;
@property (nonatomic, retain)	NSNumber*	glucose;
@property (nonatomic, retain)	NSString*	glucoseUnits;
@property (nonatomic, readonly)	NSMutableArray*	insulin;
@property (nonatomic, copy)		NSString*	note;
@property (nonatomic, retain)	NSDate*		timestamp;

+ (unsigned)insertNewLogEntryIntoDatabase:(sqlite3*)database;	//Insert a new LogEntry
+ (void) deleteDosesForInsulinTypeID:(unsigned)typeID fromDatabase:(sqlite3*)database;
+ (void) deleteLogEntriesForInsulinTypeID:(unsigned)typeID fromDatabase:(sqlite3*)database;
+ (unsigned) numLogEntriesForInsulinTypeID:(unsigned)typeID database:(sqlite3*)database;

+ (void)finalizeStatements;		// Finalize (delete) all of the SQLite compiled queries
+ (NSData*) createCSV:(sqlite3*)database from:(NSDate*)from to:(NSDate*)to;

- (id)initWithID:(unsigned)eid database:(sqlite3 *)db;
- (void)deleteFromDatabase:(sqlite3 *)db;
//- (void)dehydrate:(sqlite3 *)db;	// Flush and reduce memory footprint
- (void)flush:(sqlite3 *)db;		// Flush to database if dirty
- (void) setEditing:(BOOL)edit;

- (void) addDoseWithType:(InsulinType*)t;
- (void) removeDoseAtIndex:(unsigned)i;

- (void) setCategoryWithID:(unsigned)cid;
- (void) setCategory:(Category*)c;
- (void) setDose:(NSNumber*)d insulinDose:(InsulinDose*)dose;
- (void) setDoseType:(InsulinType*)type at:(unsigned)index;
- (void) setGlucose:(NSNumber*)g;
- (void) setNote:(NSString*)n;
- (void) setTimestamp:(NSDate*)ts;

@end
