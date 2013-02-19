#import "Constants.h"
#import "NumberFieldCell.h"

#import "ManagedLogEntry+App.h"

@interface NumberFieldCell () <NumberFieldDelegate>
@end

@implementation NumberFieldCell
{
    UILabel*	label;
}

@synthesize field;

+ (NumberFieldCell*) cellForLogEntry:(ManagedLogEntry*)logEntry accessoryView:(UIView*)accessoryView delegate:(id<NumberFieldCellDelegate>)delegate tableView:(UITableView*)tableView
{
    NumberFieldCell* cell = (NumberFieldCell*)[tableView dequeueReusableCellWithIdentifier:NSStringFromClass(self)];
    if( !cell )
    {
	cell = [[NumberFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NSStringFromClass(self)];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.clearButtonMode = UITextFieldViewModeWhileEditing;
	cell.delegate = delegate;
	cell.field.inputAccessoryView = accessoryView;
	cell.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
	cell.placeholder = @"Glucose";
    }

    // precision must be set before number so the display text is formatted correctly
    cell.precision = logEntry.glucosePrecision;
    cell.number = logEntry.glucose;
    cell.labelText = logEntry.glucoseUnitsString;

    return cell;
}
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if( self = [super initWithStyle:style reuseIdentifier:reuseIdentifier] )
    {
	self.selectionStyle = UITableViewCellSelectionStyleNone;
	
	field = [[NumberField alloc] initWithDelegate:self];
	field.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;

	[self.contentView addSubview:field];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect insetFrame = CGRectInset([self.contentView bounds], kCellLeftOffset, kCellTopOffset);
    insetFrame.size.height = kTextFieldHeight;

    if( field.hasNumber && label.text )
    {
	CGFloat x =  insetFrame.size.width / 2;
	CGRect fieldFrame = CGRectMake(insetFrame.origin.x, insetFrame.origin.y, x, insetFrame.size.height);
	CGRect unitsFrame = CGRectMake(insetFrame.origin.x+x, insetFrame.origin.y, x, insetFrame.size.height);
	field.frame = fieldFrame;
	field.textAlignment = UITextAlignmentRight;
	label.frame = unitsFrame;
	label.hidden = NO;
    }
    else
    {
	field.frame  = insetFrame;
	field.textAlignment = UITextAlignmentCenter;
	label.hidden = YES; // Hide the label in case it had been shown by a previous layout
    }
}

- (BOOL) becomeFirstResponder
{
    return [field becomeFirstResponder];
}

- (BOOL) resignFirstResponder
{
    return [field resignFirstResponder];
}


#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if( [self.delegate respondsToSelector:@selector(numberFieldCellShouldBeginEditing:)] )
	return [self.delegate numberFieldCellShouldBeginEditing:self];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if( [self.delegate respondsToSelector:@selector(numberFieldCellDidBeginEditing:)] )
	[self.delegate numberFieldCellDidBeginEditing:self];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if( [self.delegate respondsToSelector:@selector(numberFieldCellDidEndEditing:)] )
	[self.delegate numberFieldCellDidEndEditing:self];
    [self setNeedsLayout];
}


#pragma mark Propertes

- (UITextFieldViewMode) clearButtonMode
{
    return field.clearButtonMode;
}

- (void) setClearButtonMode:(UITextFieldViewMode)m
{
    field.clearButtonMode = m;
}

- (UIFont*) font
{
    return field.font;
}

- (void) setFont:(UIFont*)f
{
    field.font = f;
}

- (NSString*) labelText
{
    return label.text;
}

- (void) setLabelText:(NSString*)s
{
    if( s )
    {
	if( !label )
	{
	    label = [[UILabel alloc] initWithFrame:CGRectZero];
	    label.backgroundColor = [UIColor clearColor];
	    [self.contentView addSubview:label];
	}
	label.text = s;
    }
    else
	label = nil;
}

- (NSNumber*) number
{
    return field.number;
}

- (void) setNumber:(NSNumber*)n
{
    if( [n floatValue] )
    {
	// Need to redo layout if the cell didn't have a number before
	if( ![field hasNumber] )
	    [self setNeedsLayout];
	field.number = n;
    }
    else
    {
	// Need to redo layout if the cell had a number before
	if( [field hasNumber] )
	    [self setNeedsLayout];
	field.number = nil;
    }
}

- (NSString*) placeholder
{
    return field.placeholder;
}

- (void) setPlaceholder:(NSString*)p
{
    field.placeholder = p;
}

- (int) precision
{
    return field.precision;
}

- (void) setPrecision:(int)p
{
    field.precision = p;
}

- (UITextAlignment) textAlignment
{
    return field.textAlignment;
}

- (void) setTextAlignment:(UITextAlignment)a
{
    field.textAlignment = a;
}

@end
