#import "NumberField.h"

@interface NumberField () <UITextFieldDelegate>
@property (nonatomic, assign) id<NumberFieldDelegate>	numberFieldDelegate;
@end

@implementation NumberField
@synthesize precision;

- (id)initWithDelegate:(id<NumberFieldDelegate>)delegate
{
    if (self = [super initWithFrame:CGRectZero])
    {
	self.delegate = self;
	self.keyboardType = UIKeyboardTypeNumberPad;
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

- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    // Behave normally if not using fractional digits
    if( 0 == self.precision )
	return YES;

    NSString* s = [[[super.text stringByReplacingOccurrencesOfString:@"0." withString:@""] stringByReplacingOccurrencesOfString:@"." withString:@""] stringByAppendingString:string];

    // Allow backspace
    if( range.length && (0 == [string length]) )
        s = [s substringToIndex:(s.length - range.length)];

    const int i = s.length - 1;
    if( i > 0 )
	super.text = [NSString stringWithFormat:@"%@.%@", [s substringToIndex:i], [s substringFromIndex:i]];
    else if( i == 0 )
	super.text = [NSString stringWithFormat:@"0.%@", s];
    else
	super.text = nil;

    return NO;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
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
