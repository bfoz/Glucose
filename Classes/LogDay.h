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
}

@property (nonatomic, readonly)	float	averageGlucose;
@property (nonatomic, readonly)	unsigned	count;
@property (nonatomic, retain)	NSDate*	date;
@property (nonatomic, readonly)	NSMutableArray*	entries;
@property (nonatomic, retain)	NSString*	name;

+ (NSMutableArray*) loadAllSections:(sqlite3*)db;

- (id) initWithDate:(NSDate*)d;
- (id) initWithDate:(NSDate*)d count:(unsigned)c;

- (void) hydrate:(sqlite3*)db;
- (void) insertEntry:(LogEntry*)entry;
- (void) insertEntry:(LogEntry*)entry atIndex:(unsigned)index;
- (void) removeEntry:(LogEntry*)entry;
- (void) sortEntries;
- (void) updateStatistics;

@end
