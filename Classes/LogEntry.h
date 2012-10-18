#import <sqlite3.h>

#import "Category.h"

@class InsulinDose;
@class InsulinType;
@class LogDay;
@class LogModel;

@interface LogEntry : NSObject
{
	unsigned	entryID;
	Category*	category;
    NSNumber*	glucose;
    NSString*	glucoseString;
	NSString*	glucoseUnits;
	NSMutableArray*	insulin;
    NSString*	note;
    NSDate*		timestamp;
    BOOL	dirty;
	BOOL	hydrated;
}

@property (nonatomic, readonly)	unsigned	entryID;
@property (nonatomic, strong)	Category*	category;
@property (nonatomic, readonly)	BOOL		dirty;
@property (nonatomic, strong)	NSNumber*	glucose;
@property (unsafe_unretained, nonatomic, readonly)	NSString*	glucoseString;
@property (nonatomic, readonly) unsigned	glucosePrecision;
@property (nonatomic, strong)	NSString*	glucoseUnits;
@property (nonatomic, readonly)	NSMutableArray*	insulin;
@property (nonatomic, copy)		NSString*	note;
@property (nonatomic, strong)	NSDate*		timestamp;

#pragma mark LogEntry creation
+ (LogEntry*) createLogEntryInDatabase:(sqlite3*)database;
+ (NSMutableArray*) logEntriesForLogDay:(LogDay*)day model:(LogModel*)model;

+ (void) deleteDosesForInsulinTypeID:(unsigned)typeID fromDatabase:(sqlite3*)database;
+ (void) deleteLogEntriesForInsulinTypeID:(unsigned)typeID fromDatabase:(sqlite3*)database;
+ (BOOL) moveAllEntriesInCategory:(Category*)src toCategory:(Category*)dest database:(sqlite3*)database;
+ (unsigned) numLogEntriesForCategoryID:(unsigned)categoryID database:(sqlite3*)database;
+ (unsigned) numLogEntriesForInsulinTypeID:(unsigned)typeID database:(sqlite3*)database;
+ (NSString*) unitsStringForInteger:(unsigned)units;

+ (void) finalize;		// Finalize (delete) all of the SQLite compiled queries
+ (NSData*) createCSV:(LogModel*)model from:(NSDate*)from to:(NSDate*)to;

- (id) initWithID:(unsigned)entry date:(NSDate*)date;
- (id) initWithStatement:(sqlite3_stmt*)statement model:(LogModel*)model;

- (void)deleteFromDatabase:(sqlite3 *)db;
//- (void)dehydrate:(sqlite3 *)db;	// Flush and reduce memory footprint
- (void)flush:(sqlite3 *)db;		// Flush to database if dirty
- (void) revert:(LogModel*)model;	// Undo any changes
- (void) setEditing:(BOOL)edit model:(LogModel*)model;

- (void) addDoseWithType:(InsulinType*)t;
- (InsulinDose*) doseAtIndex:(unsigned)index;
- (void) removeDoseAtIndex:(unsigned)i;

- (void) setCategory:(Category*)c;
- (void) setDose:(NSNumber*)d insulinDose:(InsulinDose*)dose;
- (void) setDoseType:(InsulinType*)type at:(unsigned)index;
- (void) setGlucose:(NSNumber*)g;
- (void) setNote:(NSString*)n;
- (void) setTimestamp:(NSDate*)ts;

@end
