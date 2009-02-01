//
//  Category.h
//  Glucose
//
//  Created by Brandon Fosdick on 7/4/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface Category : NSObject
{
	NSInteger	categoryID;
	NSString*	categoryName;
}

@property (nonatomic, assign) NSInteger	categoryID;
@property (nonatomic, copy) NSString*	categoryName;

+ (Category*)insertNewCategoryIntoDatabase:(sqlite3*)database withName:(NSString*)n;
+ (unsigned)numRowsForCategoryID:(unsigned)cid database:(sqlite3*)database;

// Initialize with a Name and ID
- (id)initWithID:(NSInteger)type name:(NSString*)name;

@end
