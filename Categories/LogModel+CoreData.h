#import "LogModel.h"

@class ManagedCategory, ManagedInsulinType, NSFetchRequest, NSManagedObjectContext;

@interface LogModel (CoreData)

+ (NSURL*) applicationDocumentsDirectory;
+ (NSURL*) sqlitePersistentStoreURL;
+ (BOOL) persistentStoreExists;

+ (NSManagedObjectContext*) managedObjectContext;
+ (NSManagedObjectModel*) managedObjectModel;
+ (NSPersistentStoreCoordinator*) persistentStoreCoordinator;
+ (void) saveManagedObjectContext:(NSManagedObjectContext*)managedObjectContext;

+ (NSFetchRequest*) fetchRequestForLogDays;
+ (NSFetchRequest*) fetchRequestForOrderedLogDays;
+ (NSFetchRequest*) fetchRequestForOrderedCategories;
+ (NSFetchRequest*) fetchRequestForOrderedInsulinTypes;

+ (ManagedCategory*) insertManagedCategoryIntoContext:(NSManagedObjectContext*)managedObjectContext;
+ (ManagedInsulinType*) insertManagedInsulinTypeIntoContext:(NSManagedObjectContext*)managedObjectContext;
+ (ManagedInsulinType*) insertManagedInsulinTypeShortName:(NSString*)name intoContext:(NSManagedObjectContext*)managedObjectContext;
+ (ManagedInsulinType*) insertOrIgnoreManagedInsulinTypeShortName:(NSString*)name intoContext:(NSManagedObjectContext*)managedObjectContext;

@end
