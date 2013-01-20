#import "LogModel.h"

@class ManagedCategory;

@interface LogModel (SQLite)

+ (NSArray*) loadCategoriesFromDatabase:(sqlite3*)database;
+ (NSArray*) loadInsulinTypesFromDatabase:(sqlite3*)database;

+ (NSString*) bundledDatabasePath;
+ (NSString*) writeableSqliteDBPath;

+ (void) closeDatabase:(sqlite3*)database;
+ (sqlite3*) openDatabasePath:(NSString*)path;

@end
