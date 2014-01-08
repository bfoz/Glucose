#import "SplashViewController.h"

#import "UIView+App.h"

#import "Flurry.h"
#import "LogModel+Migration.h"

@interface SplashViewController ()
@property (nonatomic, strong) UIActivityIndicatorView*	activityIndicator;
@property (nonatomic, strong) UIImageView* backgroundImageView;
@property (nonatomic, strong) UIProgressView*	progressView;
@property (nonatomic, strong) UILabel*	textLabel;
@end

@implementation SplashViewController
{
    BOOL needsMigration;
    NSTimer*	twoSecondTimer;
}

- (id) init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (id)initForMigration:(BOOL)migrate
{
    self = [super initWithNibName:nil bundle:nil];
    if( self )
    {
	self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	self.backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Default"]];
	self.backgroundImageView.contentMode = UIViewContentModeCenter;
	self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
	self.textLabel = [[UILabel alloc] init];

	needsMigration = migrate;
	twoSecondTimer = nil;
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    self.backgroundImageView.frame = UIEdgeInsetsInsetRect(self.view.bounds, UIEdgeInsetsMake(0, 0, 20, 0));

    self.activityIndicator.frame = CGRectMake(0, CGRectGetMaxY(self.backgroundImageView.frame)-105, self.view.frame.size.width, 50);

    self.progressView.frame = UIEdgeInsetsInsetRect(self.activityIndicator.frame, UIEdgeInsetsMake(20, 25, 10, 25));
    self.progressView.alpha = 0;

    self.textLabel.frame = CGRectMake(0, CGRectGetMaxY(self.activityIndicator.frame), self.view.frame.size.width, 20);
    self.textLabel.backgroundColor = [UIColor clearColor];
    self.textLabel.textAlignment = NSTextAlignmentCenter;
    self.textLabel.textColor = [UIColor whiteColor];

    if( needsMigration )
	self.textLabel.text = @"Upgrading your database";

    [self.view addSubview:self.backgroundImageView];
    [self.view addSubview:self.activityIndicator];
    [self.view addSubview:self.progressView];
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
	    [Flurry endTimedEvent:@"migrateOriginalDatabaseToCoreData" withParameters:nil];
	}];

	[self.activityIndicator startAnimating];
	twoSecondTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(twoSecondTimerFired) userInfo:nil repeats:NO];

#ifndef SPECS
	__block SplashViewController* blockSelf = self;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
	    [Flurry logEvent:@"migrateOriginalDatabaseToCoreData" timed:YES];
	    NSDictionary* statistics = [LogModel migrateTheDatabaseWithProgressView:self.progressView];
	    [Flurry endTimedEvent:@"migrateOriginalDatabaseToCoreData" withParameters:statistics];

	    [application endBackgroundTask:background_Task];
	    background_Task = UIBackgroundTaskInvalid;

	    dispatch_async(dispatch_get_main_queue(), ^{
		[blockSelf didFinishMigration];
	    });
	});
#endif
    }
    else
	[self didFinishMigration];
}

- (void) twoSecondTimerFired
{
    [self.view animateWithDuration:1
			animations:^{
			    self.activityIndicator.alpha = 0;
			    self.progressView.alpha = 1;
			} completion:^(BOOL finished) {
			    self.activityIndicator.hidden = YES;
			    self.progressView.hidden = NO;
			}];
}

- (void) didFinishMigration
{
    [twoSecondTimer invalidate];
    twoSecondTimer = nil;

    if( self.delegate )
	[self.delegate splashViewControllerDidFinish];
}

@end
