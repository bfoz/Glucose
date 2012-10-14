#import "UIControl+SpecHelper.h"

@implementation UIControl (SpecHelper)

- (void)tap
{
    [self sendActionsForControlEvents:UIControlEventTouchUpInside];
}

@end

