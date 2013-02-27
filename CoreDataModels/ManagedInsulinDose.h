//
//  ManagedInsulinDose.h
//  Glucose
//
//  Created by Brandon Fosdick on 02/26/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ManagedInsulinType, ManagedLogEntry;

@interface ManagedInsulinDose : NSManagedObject

@property (nonatomic, retain) NSNumber * quantity;
@property (nonatomic, retain) ManagedInsulinType *insulinType;
@property (nonatomic, retain) ManagedLogEntry *logEntry;

@end
