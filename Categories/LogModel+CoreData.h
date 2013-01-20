#import "LogModel.h"

@class ManagedCategory, ManagedInsulinType, NSFetchRequest, NSManagedObjectContext;

@interface LogModel (CoreData)

+ (NSURL*) applicationDocumentsDirectory;
+ (NSURL*) sqlitePersistentStoreURL;

+ (NSManagedObjectContext*) managedObjectContext;
+ (NSManagedObjectModel*) managedObjectModel;
+ (NSPersistentStoreCoordinator*) persistentStoreCoordinator;
+ (void) saveManagedObjectContext:(NSManagedObjectContext*)managedObjectContext;

+ (NSFetchRequest*) fetchRequestForLogDaysInContext:(NSManagedObjectContext*)managedObjectContext;
+ (NSFetchRequest*) fetchRequestForOrderedLogDaysInContext:(NSManagedObjectContext*)managedObjectContext;
+ (NSFetchRequest*) fetchRequestForOrderedCategoriesInContext:(NSManagedObjectContext*)managedObjectContext;
+ (NSFetchRequest*) fetchRequestForOrderedInsulinTypesInContext:(NSManagedObjectContext*)managedObjectContext;

+ (ManagedCategory*) insertManagedCategoryIntoContext:(NSManagedObjectContext*)managedObjectContext;
+ (ManagedInsulinType*) insertManagedInsulinTypeIntoContext:(NSManagedObjectContext*)managedObjectContext;
+ (ManagedInsulinType*) insertManagedInsulinTypeShortName:(NSString*)name intoContext:(NSManagedObjectContext*)managedObjectContext;
+ (ManagedInsulinType*) insertOrIgnoreManagedInsulinTypeShortName:(NSString*)name intoContext:(NSManagedObjectContext*)managedObjectContext;

@end
