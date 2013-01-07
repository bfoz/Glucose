//
//  ManagedInsulinType.h
//  Glucose
//
//  Created by Brandon Fosdick on 01/06/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ManagedInsulinDose;

@interface ManagedInsulinType : NSManagedObject

@property (nonatomic) int32_t sequenceNumber;
@property (nonatomic, retain) NSString * shortName;
@property (nonatomic, retain) NSSet *insulinDoses;
@end

@interface ManagedInsulinType (CoreDataGeneratedAccessors)

- (void)addInsulinDosesObject:(ManagedInsulinDose *)value;
- (void)removeInsulinDosesObject:(ManagedInsulinDose *)value;
- (void)addInsulinDoses:(NSSet *)values;
- (void)removeInsulinDoses:(NSSet *)values;

@end
