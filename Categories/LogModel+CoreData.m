#import <CoreData/CoreData.h>

#import "LogModel+CoreData.h"

#import "ManagedCategory.h"
#import "ManagedInsulinType.h"

#import "Category.h"
#import "InsulinType.h"

@implementation LogModel (CoreData)

+ (NSURL*) applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

+ (NSURL*) sqlitePersistentStoreURL
{
    return [[LogModel applicationDocumentsDirectory] URLByAppendingPathComponent:@"GlucoseCoreData.sqlite"];
}

+ (NSFetchRequest*) fetchRequestForOrderedCategoriesInContext:(NSManagedObjectContext*)managedObjectContext
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription* entity = [NSEntityDescription entityForName:@"Category" inManagedObjectContext:managedObjectContext];
    fetchRequest.entity = entity;

    NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sequenceNumber" ascending:YES];
    fetchRequest.sortDescriptors = @[sortDescriptor];

    return fetchRequest;
}

+ (NSFetchRequest*) fetchRequestForOrderedInsulinTypesInContext:(NSManagedObjectContext*)managedObjectContext
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription* entity = [NSEntityDescription entityForName:@"InsulinType" inManagedObjectContext:managedObjectContext];
    fetchRequest.entity = entity;

    NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sequenceNumber" ascending:YES];
    fetchRequest.sortDescriptors = @[sortDescriptor];

    return fetchRequest;
}

+ (ManagedCategory*) insertManagedCategoryIntoContext:(NSManagedObjectContext*)managedObjectContext
{
    return [NSEntityDescription insertNewObjectForEntityForName:@"Category" inManagedObjectContext:managedObjectContext];
}

+ (ManagedInsulinType*) insertManagedInsulinTypeIntoContext:(NSManagedObjectContext*)managedObjectContext
{
    return [NSEntityDescription insertNewObjectForEntityForName:@"InsulinType" inManagedObjectContext:managedObjectContext];
}

@end
