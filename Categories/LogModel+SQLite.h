#import "LogModel.h"

@interface LogModel (SQLite)

+ (NSMutableArray*) loadCategoriesFromDatabase:(sqlite3*)database;
+ (NSMutableArray*) loadInsulinTypesFromDatabase:(sqlite3*)database;

+ (NSString*) bundledDatabasePath;
+ (NSString*) writeableSqliteDBPath;

+ (void) closeDatabase:(sqlite3*)database;
+ (sqlite3*) openDatabasePath:(NSString*)path;

@end
