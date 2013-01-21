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
    [self.activityIndicator startAnimating];

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
	[LogModel checkForMigration];

    if( self.delegate )
	[self.delegate splashViewControllerDidFinish];
}

@end
