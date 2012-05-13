#import "SpecHelper.h"
#import "OCMock.h"

#import "AppDelegate.h"

//#import "LogViewController.h"

using namespace Cedar::Matchers;

SPEC_BEGIN(AppDelegateSpec)

describe(@"AppDelegate", ^{
    __block AppDelegate *delegate;

    beforeEach(^{
	delegate = [[[AppDelegate alloc] init] autorelease];
    });

    beforeEach(^{
	[delegate application:nil didFinishLaunchingWithOptions:nil];
    });

    it(@"should have a UINavigationController", ^{
	delegate.navController should_not be_nil;
	delegate.navController should be_instance_of([UINavigationController class]);
    });

    it(@"should have a LogViewController", ^{
	delegate.navController.topViewController should_not be_nil;
//	delegate.navController.topViewController should be_instance_of([LogViewController class]);
    });
});

SPEC_END
