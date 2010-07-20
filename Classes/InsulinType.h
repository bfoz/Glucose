//
//  InsulinType.h
//  Glucose
//
//  Created by Brandon Fosdick on 7/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface InsulinType : NSObject
{
	NSInteger	typeID;
	NSString*	shortName;
}

@property (nonatomic, readonly)	NSInteger	typeID;
@property (nonatomic, copy)	NSString*	shortName;

+ (BOOL) insertInsulinType:(InsulinType*)t intoDatabase:(sqlite3*)database;
+ (InsulinType*)insertNewInsulinTypeIntoDatabase:(sqlite3*)database withName:(NSString*)n;

// Initialize with a Name and ID
- (id)initWithID:(NSInteger)type name:(NSString*)name;

- (void) deleteFromDatabase:(sqlite3*)database;

@end
