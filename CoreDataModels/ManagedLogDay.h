//
//  ManagedLogDay.h
//  Glucose
//
//  Created by Brandon Fosdick on 01/13/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ManagedLogEntry;

@interface ManagedLogDay : NSManagedObject

@property (nonatomic, retain) NSNumber * averageGlucose;
@property (nonatomic, retain) NSString * averageGlucoseString;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSOrderedSet *logEntries;
@end

@interface ManagedLogDay (CoreDataGeneratedAccessors)

- (void)insertObject:(ManagedLogEntry *)value inLogEntriesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromLogEntriesAtIndex:(NSUInteger)idx;
- (void)insertLogEntries:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeLogEntriesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInLogEntriesAtIndex:(NSUInteger)idx withObject:(ManagedLogEntry *)value;
- (void)replaceLogEntriesAtIndexes:(NSIndexSet *)indexes withLogEntries:(NSArray *)values;
- (void)addLogEntriesObject:(ManagedLogEntry *)value;
- (void)removeLogEntriesObject:(ManagedLogEntry *)value;
- (void)addLogEntries:(NSOrderedSet *)values;
- (void)removeLogEntries:(NSOrderedSet *)values;
@end
