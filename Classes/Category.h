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
+ (Category*) newCategoryWithName:(NSString*)n database:(sqlite3*)database;

// Initialize with a Name and ID
- (id)initWithID:(NSInteger)type name:(NSString*)name;

- (void) flush:(sqlite3*)database;

@end
