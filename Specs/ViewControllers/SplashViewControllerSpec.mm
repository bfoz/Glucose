#import "SpecsHelper.h"
#import "SplashViewController.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

@interface SplashViewController ()

@property (nonatomic, strong) UIActivityIndicatorView*	activityIndicator;
@property (nonatomic, strong) UIImageView* backgroundImageView;
@property (nonatomic, strong) UIProgressView*	progressView;
@property (nonatomic, strong) UILabel*	textLabel;

- (void) didFinishMigration;
- (void) twoSecondTimerFired;

@end

SPEC_BEGIN(SplashViewControllerSpec)

describe(@"SplashViewController", ^{
    __block SplashViewController* controller;
    __block id mockDelegate;

    beforeEach(^{
	mockDelegate = nice_fake_for(@protocol(SplashViewControllerDelegate));
    });

    describe(@"when the database needs migration", ^{
	beforeEach(^{
	    controller = [[SplashViewController alloc] initForMigration:YES];
	    controller.delegate = mockDelegate;

	    controller.view should_not be_nil;
	    [controller viewDidAppear:NO];
	});

	it(@"should have a background image", ^{
	    controller.backgroundImageView.image should equal([UIImage imageNamed:@"LaunchImage"]);
	});

	it(@"should start the activity spinner", ^{
	    controller.activityIndicator.isAnimating should be_truthy;
	});

	describe(@"when the migration takes more than 2 seconds", ^{
	    beforeEach(^{
		[controller twoSecondTimerFired];
	    });

	    it(@"should replace the spinner with a progress bar", ^{
		controller.activityIndicator.hidden should be_truthy;
		controller.progressView.hidden should_not be_truthy;
	    });
	});

	describe(@"when the migration finishes", ^{
	    beforeEach(^{
		[controller didFinishMigration];
	    });

	    it(@"should inform the delegate", ^{
		mockDelegate should have_received("splashViewControllerDidFinish");
	    });
	});
    });

    describe(@"when the database does not need migration", ^{
	beforeEach(^{
	    controller = [[SplashViewController alloc] initForMigration:NO];
	    controller.delegate = mockDelegate;

	    controller.view should_not be_nil;
	    [controller viewDidAppear:NO];
	});

	it(@"should inform the delegate", ^{
	    mockDelegate should have_received("splashViewControllerDidFinish");
	});
    });
});

SPEC_END
