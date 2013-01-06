//
//  ManagedInsulinDose.h
//  Glucose
//
//  Created by Brandon Fosdick on 01/05/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ManagedInsulinType, ManagedLogEntry;

@interface ManagedInsulinDose : NSManagedObject

@property (nonatomic, retain) NSNumber * dose;
@property (nonatomic, retain) ManagedInsulinType *insulinType;
@property (nonatomic, retain) ManagedLogEntry *logEntry;

@end
