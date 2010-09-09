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

+ (BOOL) deleteCategory:(Category*)c fromDatabase:(sqlite3*)database;
+ (BOOL) insertCategory:(Category*)c intoDatabase:(sqlite3*)database;
+ (Category*)insertNewCategoryIntoDatabase:(sqlite3*)database withName:(NSString*)n;
+ (BOOL) loadCategories:(NSMutableArray*)result fromDatabase:(sqlite3*)database;
+ (unsigned)numRowsForCategoryID:(unsigned)cid database:(sqlite3*)database;

// Initialize with a Name and ID
- (id)initWithID:(NSInteger)type name:(NSString*)name;

- (void) flush:(sqlite3*)database;

@end
