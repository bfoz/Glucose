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
@class LogModel;

@interface LogDay : NSObject
{
	float			averageGlucose;
	unsigned		count;
	NSDate*			date;
	NSMutableArray*	entries;
	NSString*		name;
    NSString*		averageGlucoseString;
    NSString*		__unsafe_unretained units;
}

@property (nonatomic, readonly)	float	averageGlucose;
@property (unsafe_unretained, nonatomic, readonly)	NSString*	averageGlucoseString;
@property (nonatomic, readonly)	unsigned	count;
@property (nonatomic, strong)	NSDate*	date;
@property (nonatomic, readonly)	NSMutableArray*	entries;
@property (nonatomic, strong)	NSString*	name;
@property (unsafe_unretained, nonatomic, readonly)	NSString*	units;

+ (unsigned) loadDays:(NSMutableArray*)days fromDatabase:(sqlite3*)database limit:(unsigned)limit offset:(unsigned)offset;
+ (unsigned) numberOfDays:(sqlite3*)db;

- (id) initWithDate:(NSDate*)d;

- (void) deleteAllEntriesFromDatabase:(sqlite3*)database;
- (void) deleteEntry:(LogEntry*)entry fromDatabase:(sqlite3*)database;
- (void) hydrate:(LogModel*)model database:(sqlite3*)database;
- (void) insertEntry:(LogEntry*)entry;
- (void) insertEntry:(LogEntry*)entry atIndex:(unsigned)index;
- (void) sortEntries;
- (void) updateStatistics;

@end
