#import "AppDelegate.h"

#import <DropboxSDK/DropboxSDK.h>

#import "Category.h"
#import "Constants.h"
#import "InsulinDose.h"
#import "InsulinType.h"
#import "LogEntry.h"
#import "LogDay.h"
#import "LogModel+SQLite.h"
#import "LogViewController.h"

#ifdef APPSTORE
#import "Flurry.h"
#endif

AppDelegate* appDelegate = nil;

static NSString *const dropboxAppKey	= @"pl5fl3zf43pk9c4";
static NSString *const dropboxAppSecret = @"iw9oh6wtbg404s1";

NSString* kDropboxSessionLinkedAccountNotification = @"DropboxSessionLinkedAccountNotification";
NSString* kDropboxSessionUnlinkedAccountNotification = @"DropboxSessionUnlinkedAccountNotification";

@interface AppDelegate () <LogViewDelegate>
@end

@implementation AppDelegate

@synthesize window;
@synthesize navController;

NSDateFormatter* shortDateFormatter = nil;

#pragma mark -
#pragma mark <UIApplicationDelegate>

- (BOOL) application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
#ifdef APPSTORE
    [Flurry startSession:@"X4DCQH62JV4JXP72BJJR"];
#endif

    // Create the top level window (instead of using a default nib)
    window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    // Initialize the global application delegate pointer
    appDelegate = self;

	// Set the background color for the flip animation going to/from the settings view
	//  The background color is what shows up behind the flipping views
	window.backgroundColor = [UIColor blackColor];
	
    DBSession* session = [[DBSession alloc] initWithAppKey:dropboxAppKey
						 appSecret:dropboxAppSecret
						      root:kDBRootAppFolder];
    [DBSession setSharedSession:session];

    // Create the Log Model object
    model = [[LogModel alloc] init];
    if( !model )
    {
	NSLog(@"Could not create a LogModel");
	return NO;
    }

    LogViewController* logViewController = [[LogViewController alloc] initWithModel:model delegate:self];
    UINavigationController* aNavigationController = [[UINavigationController alloc] initWithRootViewController:logViewController];
    self.navController = aNavigationController;


    // The application ships with a default database in its bundle. If anything in the application
    // bundle is altered, the code sign will fail. We want the database to be editable by users, 
    // so we need to create a copy of it in the application's Documents directory.     
    [self createEditableCopyOfDatabaseIfNeeded];

    [window addSubview:[navController view]];
    [window makeKeyAndVisible];

    return YES;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    DBSession* session = [DBSession sharedSession];
    if( [session handleOpenURL:url] )
    {
        if( session.isLinked )
	{
	    [[NSNotificationCenter defaultCenter] postNotificationName:kDropboxSessionLinkedAccountNotification object:session];
        }
        return YES;
    }
    // Add whatever other url handling code your app requires here
    return NO;
}

#pragma mark -
#pragma mark <LogViewDelegate>

#pragma mark -
#pragma mark Database Initialization

// Creates a writable copy of the bundled default database in the application Documents directory.
- (void)createEditableCopyOfDatabaseIfNeeded
{
    // First, test for existence.
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString *writableDBPath = [LogModel writeableSqliteDBPath];
    if( [fileManager fileExistsAtPath:writableDBPath] )
	return;

    NSLog(@"Database did not exist\n");
    // The writable database does not exist, so copy the default to the appropriate location.
    NSError *error;
    BOOL success = [fileManager copyItemAtPath:[LogModel bundledDatabasePath]
					toPath:writableDBPath
					 error:&error];
    if( !success )
        NSAssert1(0, @"Failed to create writable database file with message '%@'.", [error localizedDescription]);
}

#pragma mark -
#pragma mark Properties

// This is a dummy property to get KVO to work on the dummy entries key
- (NSMutableArray*)entries
{
	return nil;
}

@end
