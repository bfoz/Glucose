#import "DateField.h"

@implementation DateField
{
    UIDatePicker* datePicker;
    UIToolbar*    toolbar;
}

@synthesize delegate = __delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if( self )
    {
	self.inputView = self.datePicker;
	self.inputAccessoryView = self.toolbar;
    }
    return self;
}

- (NSDate*) date
{
    return self.datePicker.date;
}

- (void) setDate:(NSDate *)date
{
    self.datePicker.date = date;
}

- (void) setDelegate:(id<DateFieldDelegate>)delegate
{
    __delegate = delegate;
    super.delegate = delegate;
}

- (UIDatePicker*) datePicker
{
    if( !datePicker )
    {
	datePicker = [[UIDatePicker alloc] init];
	datePicker.datePickerMode = UIDatePickerModeDateAndTime;
	[datePicker addTarget:self action:@selector(datePickerDidChangeValue:) forControlEvents:UIControlEventValueChanged];
    }
    return datePicker;
}

- (UIToolbar*) toolbar
{
    if( !toolbar )
    {
	toolbar = [[UIToolbar alloc] init];
	UIBarButtonItem* cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(didTapCancelButton)];
	UIBarButtonItem* flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	UIBarButtonItem* barButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didTapDoneButton)];
	[toolbar setItems:[NSArray arrayWithObjects:cancelButton, flexibleSpace, barButton, nil] animated:NO];
	[toolbar sizeToFit];
    }

    return toolbar;
}

# pragma mark Actions

- (void) datePickerDidChangeValue:(id)sender
{
    if( [self.delegate respondsToSelector:@selector(dateFieldDidChangeValue:)] )
	[(id<DateFieldDelegate>)self.delegate dateFieldDidChangeValue:self];
}

- (void) didTapCancelButton
{
    if( [self.delegate respondsToSelector:@selector(dateFieldWillCancelEditing:)] )
	[(id<DateFieldDelegate>)self.delegate dateFieldWillCancelEditing:self];
    [self resignFirstResponder];
}

- (void) didTapDoneButton
{
    [self resignFirstResponder];
}

@end
