#import "SplashViewController.h"

#import "LogModel+Migration.h"

@interface SplashViewController ()
@property (nonatomic, strong) UIActivityIndicatorView*	activityIndicator;
@property (nonatomic, strong) UIImageView* backgroundImageView;
@property (nonatomic, strong) UILabel*	textLabel;
@end

@implementation SplashViewController
{
    BOOL needsMigration;
}

- (id)init
{
    self = [super initWithNibName:nil bundle:nil];
    if( self )
    {
	self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	self.backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Default"]];
	self.backgroundImageView.contentMode = UIViewContentModeCenter;
	self.textLabel = [[UILabel alloc] init];

	needsMigration = [LogModel needsMigration];
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    self.backgroundImageView.frame = UIEdgeInsetsInsetRect(self.view.bounds, UIEdgeInsetsMake(0, 0, 20, 0));

    self.activityIndicator.frame = CGRectMake(0, CGRectGetMaxY(self.backgroundImageView.frame)-105, self.view.frame.size.width, 50);

    self.textLabel.frame = CGRectMake(0, CGRectGetMaxY(self.activityIndicator.frame), self.view.frame.size.width, 20);
    self.textLabel.backgroundColor = [UIColor clearColor];
    self.textLabel.textAlignment = UITextAlignmentCenter;
    self.textLabel.textColor = [UIColor whiteColor];

    if( needsMigration )
	self.textLabel.text = @"Upgrading your database";

    [self.view addSubview:self.backgroundImageView];
    [self.view addSubview:self.activityIndicator];
    [self.view addSubview:self.textLabel];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if( needsMigration )
    {
	UIApplication* application = [UIApplication sharedApplication];
	__block UIBackgroundTaskIdentifier background_Task = [application beginBackgroundTaskWithExpirationHandler:^{
	    [application endBackgroundTask:background_Task];
	    background_Task = UIBackgroundTaskInvalid;
	}];

	[self.activityIndicator startAnimating];

	__block SplashViewController* blockSelf = self;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
	    [LogModel migrateTheDatabase];

	    [application endBackgroundTask:background_Task];
	    background_Task = UIBackgroundTaskInvalid;

	    dispatch_async(dispatch_get_main_queue(), ^{
		[blockSelf didFinish];
	    });
	});
    }
    else
	[self didFinish];
}

- (void) didFinish
{
    if( self.delegate )
	[self.delegate splashViewControllerDidFinish];
}

@end
