//
//  LogDay.h
//  Glucose
//
//  Created by Brandon Fosdick on 11/4/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@class LogEntry;

@interface LogDay : NSObject
{
	float			averageGlucose;
	unsigned		count;
	NSDate*			date;
	NSMutableArray*	entries;
	NSString*		name;
    NSString*		averageGlucoseString;
    NSString*		units;
}

@property (nonatomic, readonly)	float	averageGlucose;
@property (nonatomic, readonly)	NSString*	averageGlucoseString;
@property (nonatomic, readonly)	unsigned	count;
@property (nonatomic, retain)	NSDate*	date;
@property (nonatomic, readonly)	NSMutableArray*	entries;
@property (nonatomic, retain)	NSString*	name;
@property (nonatomic, readonly)	NSString*	units;

+ (unsigned) loadDays:(NSMutableArray*)days fromDatabase:(sqlite3*)database limit:(unsigned)limit offset:(unsigned)offset;
+ (unsigned) numberOfDays:(sqlite3*)db;

- (id) initWithDate:(NSDate*)d;

- (void) deleteAllEntriesFromDatabase:(sqlite3*)database;
- (void) hydrate:(sqlite3*)db;
- (void) insertEntry:(LogEntry*)entry;
- (void) insertEntry:(LogEntry*)entry atIndex:(unsigned)index;
- (void) removeEntry:(LogEntry*)entry;
- (void) sortEntries;
- (void) updateStatistics;

@end
