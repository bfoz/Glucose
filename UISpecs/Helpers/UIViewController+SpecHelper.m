#import "UIViewController+SpecHelper.h"
#import <objc/runtime.h>
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

@implementation UIViewController (SpecHelper)

#pragma mark - Modals
- (void)presentModalViewController:(UIViewController *)modalViewController animated:(BOOL)animated {
    self.modalViewController = modalViewController;
    modalViewController.presentingViewController = self;
}

- (void)setModalViewController:(UIViewController *)modalViewController {
    objc_setAssociatedObject(self, "modalViewController", modalViewController, OBJC_ASSOCIATION_RETAIN);
}

- (void)dismissModalViewControllerAnimated:(BOOL)animated {
    self.modalViewController.presentingViewController = nil;
    self.modalViewController = nil;
}

- (UIViewController *)modalViewController {
    return objc_getAssociatedObject(self, "modalViewController");
}

- (void)setPresentingViewController:(UIViewController *)presentingViewController {
    objc_setAssociatedObject(self, "presentingViewController", presentingViewController, OBJC_ASSOCIATION_RETAIN);
}

- (UIViewController *)presentingViewController {
    return objc_getAssociatedObject(self, "presentingViewController");
}


#pragma mark - Animation
- (void)animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion {
    animations();
    completion(YES);
}


@end
