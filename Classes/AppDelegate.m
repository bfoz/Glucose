#import "AppDelegate.h"

#import <DropboxSDK/DropboxSDK.h>

#import "LogModel+CoreData.h"
#import "LogViewController.h"
#import "SplashViewController.h"

#ifdef APPSTORE
#import "Flurry.h"
#endif

AppDelegate* appDelegate = nil;

static NSString *const dropboxAppKey	= @"pl5fl3zf43pk9c4";
static NSString *const dropboxAppSecret = @"iw9oh6wtbg404s1";

NSString* kDropboxSessionLinkedAccountNotification = @"DropboxSessionLinkedAccountNotification";
NSString* kDropboxSessionUnlinkedAccountNotification = @"DropboxSessionUnlinkedAccountNotification";

@interface AppDelegate () <LogViewDelegate, SplashViewControllerDelegate>
@property (nonatomic, strong) UINavigationController*	navigationController;
@end

@implementation AppDelegate
{
    UIWindow* window;
}

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

    SplashViewController* splashViewController = [[SplashViewController alloc] init];
    splashViewController.delegate = self;

    UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:splashViewController];
    navigationController.navigationBarHidden = YES;
    self.navigationController = navigationController;

    window.rootViewController = self.navigationController;
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

#pragma mark - Accessors

- (LogModel*) model
{
    if( !_model )
	_model = [[LogModel alloc] init];
    return _model;
}

#pragma mark - SplashViewControllerDelegate

- (void) splashViewControllerDidFinish
{
    LogViewController* logViewController = [[LogViewController alloc] initWithModel:self.model delegate:self];
    UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:logViewController];

    [UIView transitionFromView:self.navigationController.view
			toView:navigationController.view
		      duration:1.0
		       options:UIViewAnimationOptionTransitionCurlUp
		    completion:^(BOOL finished) {
			self.navigationController = navigationController;
			self.window.rootViewController = self.navigationController;
		    }];
}
@end
