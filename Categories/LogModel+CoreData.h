#import "LogModel.h"

@class ManagedCategory, ManagedInsulinType;

@interface LogModel (CoreData)

+ (NSURL*) applicationDocumentsDirectory;
+ (NSURL*) sqlitePersistentStoreURL;

+ (NSFetchRequest*) fetchRequestForOrderedCategoriesInContext:(NSManagedObjectContext*)managedObjectContext;
+ (NSFetchRequest*) fetchRequestForOrderedInsulinTypesInContext:(NSManagedObjectContext*)managedObjectContext;

+ (ManagedCategory*) insertManagedCategoryIntoContext:(NSManagedObjectContext*)managedObjectContext;
+ (ManagedInsulinType*) insertManagedInsulinTypeIntoContext:(NSManagedObjectContext*)managedObjectContext;

@end
