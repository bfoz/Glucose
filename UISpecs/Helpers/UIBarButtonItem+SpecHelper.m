#import "UIBarButtonItem+SpecHelper.h"

#import "UIControl+SpecHelper.h"

@implementation UIBarButtonItem (SpecHelper)

- (void)tap
{
    if( [self.customView isKindOfClass:[UIButton class]] )
        [(UIButton*)self.customView tap];
    else
        [self.target performSelector:self.action];
}

@end
