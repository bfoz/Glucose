#import <UIKit/UIKit.h>

@protocol NumberFieldDelegate <UITextFieldDelegate>
@end

@interface NumberField : UITextField

@property (nonatomic, copy)	NSNumber*	number;
@property (nonatomic, assign)	unsigned	precision;

- (id)initWithDelegate:(id<NumberFieldDelegate>)delegate;

- (BOOL) hasNumber;

@end
