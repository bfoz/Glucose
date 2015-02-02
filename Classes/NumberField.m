#import "NumberField.h"

@interface NumberField () <UITextFieldDelegate>
@property (nonatomic, unsafe_unretained) id<NumberFieldDelegate>	numberFieldDelegate;
@end

@implementation NumberField
@synthesize precision;

- (id)initWithDelegate:(id<NumberFieldDelegate>)delegate
{
    if (self = [super initWithFrame:CGRectZero])
    {
	self.delegate = self;
	self.numberFieldDelegate = delegate;
    }
    return self;
}

#pragma mark Propertes

- (NSNumber*) number
{
    return [self hasNumber] ? [NSNumber numberWithFloat:[super.text floatValue]] : nil;
}

- (BOOL) hasNumber
{
    return super.text && super.text.length;
}

- (void) setNumber:(NSNumber*)n
{
    self.text = [n floatValue] ? [NSString localizedStringWithFormat:@"%.*f", precision, [n floatValue]] : nil;
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    // Locales that use non-integer glucose, or insulin dose, values need a decimal point on the keyboard
    self.keyboardType = (0 == self.precision) ? UIKeyboardTypeNumberPad : UIKeyboardTypeDecimalPad;

    if( [self.numberFieldDelegate respondsToSelector:@selector(textFieldShouldBeginEditing:)] )
	return [self.numberFieldDelegate textFieldShouldBeginEditing:self];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if( [self.numberFieldDelegate respondsToSelector:@selector(textFieldDidBeginEditing:)] )
	[self.numberFieldDelegate textFieldDidBeginEditing:self];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if( [self.numberFieldDelegate respondsToSelector:@selector(textFieldDidEndEditing:)] )
	[self.numberFieldDelegate textFieldDidEndEditing:self];
    [self setNeedsLayout];
}

@end
