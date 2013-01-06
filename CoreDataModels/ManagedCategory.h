//
//  ManagedCategory.h
//  Glucose
//
//  Created by Brandon Fosdick on 01/05/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ManagedLogEntry;

@interface ManagedCategory : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * sequenceNumber;
@property (nonatomic, retain) NSSet *logEntries;
@end

@interface ManagedCategory (CoreDataGeneratedAccessors)

- (void)addLogEntriesObject:(ManagedLogEntry *)value;
- (void)removeLogEntriesObject:(ManagedLogEntry *)value;
- (void)addLogEntries:(NSSet *)values;
- (void)removeLogEntries:(NSSet *)values;

@end
