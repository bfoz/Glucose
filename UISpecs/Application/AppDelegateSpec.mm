#import "SpecsHelper.h"

#import "AppDelegate.h"

#import "SplashViewController.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(AppDelegateSpec)

describe(@"AppDelegate", ^{
    __block AppDelegate* delegate;

    beforeEach(^{
	delegate = [[[AppDelegate alloc] init] autorelease];
	[delegate application:nil didFinishLaunchingWithOptions:nil];
    });

    it(@"should have a navigation controller", ^{
	delegate.navigationController should_not be_nil;
	delegate.navigationController should be_instance_of([UINavigationController class]);
    });

    it(@"should show the splash view", ^{
	delegate.navigationController.topViewController should_not be_nil;
//	delegate.navigationController.topViewController should be_instance_of([SplashViewController class]);
    });
});

SPEC_END
