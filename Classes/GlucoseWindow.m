#import "GlucoseWindow.h"


@implementation GlucoseWindow

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent*)event
{
    // Post a notification when the user finishes shaking the device
    if( UIEventSubtypeMotionShake == motion )
	[[NSNotificationCenter defaultCenter] postNotificationName:@"shaken" object:self];
}

@end
