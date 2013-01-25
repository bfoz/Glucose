#import <CoreData/CoreData.h>

#import "SpecsHelper.h"
#import "LogModel+CoreData.h"
#import "LogModel+Migration.h"
#import "LogModel+SQLite.h"

#import "ManagedLogDay.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

#define	kDefaultInsulinTypes	@"DefaultInsulinTypes"
static NSString* kSettingsNewEntryInsulinTypes	= @"SettingsNewEntryInsulinTypes";

NSString* pathForFixtureDatabase(NSString* fixtureName)
{
    NSString* fixturesDirectory = @FIXTURES_DIRECTORY;
    NSString* filePath = [NSString pathWithComponents:@[fixturesDirectory, fixtureName]];

    if( [[NSFileManager defaultManager] fileExistsAtPath:filePath] )
        return filePath;

    NSString *message = [NSString stringWithFormat:@"No fixture found for '%@'\nCurrent working directory:'%@'\nFake responses directory: '%@'",
                         fixtureName,
                         [[NSFileManager defaultManager] currentDirectoryPath],
                         fixturesDirectory];
    @throw [NSException exceptionWithName:@"FileNotFound" reason:message userInfo:nil];
}

SPEC_BEGIN(LogModel_MigrationSpec)

describe(@"LogModel+Migration", ^{
    __block NSFileManager* fileManager;
    __block LogModel* model;

    beforeEach(^{
	model = [[[LogModel alloc] init] autorelease];
    });

    describe(@"when the original sqlite file doesn't exist", ^{
	beforeEach(^{
	    [[NSFileManager defaultManager] fileExistsAtPath:[LogModel writeableSqliteDBPath]] should_not be_truthy;
	});

	it(@"should not need migration", ^{
	    [LogModel needsMigration] should_not be_truthy;
	});
    });

    describe(@"when the original sqlite file exists", ^{
	beforeEach(^{
	    fileManager = [NSFileManager defaultManager];
	    [fileManager copyItemAtPath:pathForFixtureDatabase(@"large.sqlite") toPath:[LogModel writeableSqliteDBPath] error:nil];
	    [fileManager fileExistsAtPath:[LogModel writeableSqliteDBPath]] should be_truthy;
	});

	afterEach(^{
	    [fileManager removeItemAtPath:[LogModel writeableSqliteDBPath] error:nil];
	});

	describe(@"when the backup file exists", ^{
	    beforeEach(^{
		[fileManager copyItemAtPath:pathForFixtureDatabase(@"large.sqlite") toPath:[LogModel backupPath] error:nil];
		[fileManager fileExistsAtPath:[LogModel backupPath]] should be_truthy;
	    });
	    
	    afterEach(^{
		[fileManager removeItemAtPath:[LogModel backupPath] error:nil];
	    });
	    
	    it(@"should not need migration", ^{
		[LogModel needsMigration] should_not be_truthy;
	    });
	});

	describe(@"when the backup file does not exist", ^{
	    beforeEach(^{
		[[NSFileManager defaultManager] fileExistsAtPath:[LogModel backupPath]] should_not be_truthy;
	    });

	    it(@"should need migration", ^{
		[LogModel needsMigration] should be_truthy;
	    });

	    describe(@"when the file cannot be opened by Core Data", ^{
		it(@"should need migration", ^{
		    [LogModel needsMigration] should be_truthy;
		});
	    });
	});
    });

    describe(@"when migrating", ^{
	beforeEach(^{
	    NSArray* oldInsulinTypesForNewEntries = @[@1, @2];
	    [[NSUserDefaults standardUserDefaults] setObject:oldInsulinTypesForNewEntries forKey:kDefaultInsulinTypes];

	    fileManager = [NSFileManager defaultManager];
	    [fileManager copyItemAtPath:pathForFixtureDatabase(@"large.sqlite") toPath:[LogModel writeableSqliteDBPath] error:nil];
	    [fileManager removeItemAtPath:[LogModel backupPath] error:nil];

	    [fileManager fileExistsAtPath:[LogModel backupPath]] should_not be_truthy;
	    [fileManager fileExistsAtPath:[LogModel writeableSqliteDBPath]] should be_truthy;

	    [LogModel needsMigration] should be_truthy;
	    [LogModel migrateTheDatabaseWithProgressView:nil];
	});

	afterEach(^{
	    [fileManager removeItemAtPath:[LogModel backupPath] error:nil];
	    [fileManager removeItemAtPath:[[LogModel sqlitePersistentStoreURL] path] error:nil];
	    [fileManager removeItemAtPath:[LogModel writeableSqliteDBPath] error:nil];
	    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]];
	});

	it(@"should move the old file to the backup location", ^{
	    [[NSFileManager defaultManager] fileExistsAtPath:[LogModel backupPath]] should be_truthy;
	});

	it(@"should create a CoreData database", ^{
	    [[NSFileManager defaultManager] fileExistsAtPath:[[LogModel sqlitePersistentStoreURL] path]] should be_truthy;
	});

	it(@"should migrate the categories", ^{
	    NSManagedObjectContext* managedObjectContext = [LogModel managedObjectContext];
	    NSFetchRequest* fetchRequest = [LogModel fetchRequestForOrderedCategoriesInContext:managedObjectContext];
	    NSArray* fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:nil];
	    fetchedObjects.count should equal(9);
	});

	it(@"should migrate insulin types", ^{
	    NSManagedObjectContext* managedObjectContext = [LogModel managedObjectContext];
	    NSFetchRequest* fetchRequest = [LogModel fetchRequestForOrderedInsulinTypesInContext:managedObjectContext];
	    NSArray* fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:nil];
	    fetchedObjects.count should equal(11);
	});

	it(@"should migrate the log days", ^{
	    NSManagedObjectContext* managedObjectContext = [LogModel managedObjectContext];
	    NSFetchRequest* fetchRequest = [LogModel fetchRequestForLogDaysInContext:managedObjectContext];
	    NSArray* fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:nil];
	    fetchedObjects.count should equal(966);
	    [[[fetchedObjects objectAtIndex:0] logEntries] count] should_not equal(0);
	});

	it(@"should migrate the log entries", ^{
	    NSManagedObjectContext* managedObjectContext = [LogModel managedObjectContext];
	    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
	    fetchRequest.entity = [NSEntityDescription entityForName:@"LogEntry" inManagedObjectContext:managedObjectContext];
	    NSArray* fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:nil];
	    fetchedObjects.count should equal(2138);
	});

	it(@"should migrate NSUserDefaults", ^{
	    NSOrderedSet* newEntryInsulinTypes = [[NSUserDefaults standardUserDefaults] objectForKey:kSettingsNewEntryInsulinTypes];
	    newEntryInsulinTypes should_not be_nil;
	    newEntryInsulinTypes.count should equal(2);
	});
    });
});

SPEC_END
