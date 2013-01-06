//
//  ManagedLogEntry.h
//  Glucose
//
//  Created by Brandon Fosdick on 01/05/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ManagedCategory, ManagedInsulinDose;

@interface ManagedLogEntry : NSManagedObject

@property (nonatomic, retain) NSNumber * glucose;
@property (nonatomic, retain) NSNumber * glucoseUnits;
@property (nonatomic, retain) NSString * note;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) ManagedCategory *category;
@property (nonatomic, retain) NSOrderedSet *insulinDoses;
@end

@interface ManagedLogEntry (CoreDataGeneratedAccessors)

- (void)insertObject:(ManagedInsulinDose *)value inInsulinDosesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromInsulinDosesAtIndex:(NSUInteger)idx;
- (void)insertInsulinDoses:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeInsulinDosesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInInsulinDosesAtIndex:(NSUInteger)idx withObject:(ManagedInsulinDose *)value;
- (void)replaceInsulinDosesAtIndexes:(NSIndexSet *)indexes withInsulinDoses:(NSArray *)values;
- (void)addInsulinDosesObject:(ManagedInsulinDose *)value;
- (void)removeInsulinDosesObject:(ManagedInsulinDose *)value;
- (void)addInsulinDoses:(NSOrderedSet *)values;
- (void)removeInsulinDoses:(NSOrderedSet *)values;
@end
