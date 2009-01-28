//
//  NumberFieldCell.m
//  Glucose
//
//  Created by Brandon Fosdick on 1/22/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Constants.h"
#import "NumberFieldCell.h"

@interface NumberFieldCell ()
@property (nonatomic, retain)	UILabel*    _label;
@end

@implementation NumberFieldCell

@synthesize delegate;
@synthesize field, _label;

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier])
    {
	self.selectionStyle = UITableViewCellSelectionStyleNone;
	
	field = [[NumberField alloc] initWithFrame:CGRectZero];
	field.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	field.delegate = self;

	[self.contentView addSubview:field];
    }
    return self;
}

- (void)dealloc
{
    [field release];
    [_label release];
    [super dealloc];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect insetFrame = CGRectInset([self.contentView bounds], kCellLeftOffset, kCellTopOffset);
    insetFrame.size.height = kTextFieldHeight;

    if( field.hasNumber && _label.text )
    {
	CGFloat x =  insetFrame.size.width / 2;
	CGRect fieldFrame = CGRectMake(insetFrame.origin.x, insetFrame.origin.y, x, insetFrame.size.height);
	CGRect unitsFrame = CGRectMake(insetFrame.origin.x+x, insetFrame.origin.y, x, insetFrame.size.height);
	field.frame = fieldFrame;
	field.textAlignment = UITextAlignmentRight;
	_label.frame = unitsFrame;
	_label.hidden = NO;
    }
    else
    {
	field.frame  = insetFrame;
	field.textAlignment = UITextAlignmentCenter;
	_label.hidden = YES; // Hide the label in case it had been shown by a previous layout
    }
}

- (BOOL) becomeFirstResponder
{
    return [field becomeFirstResponder];
}

- (void) resignFirstResponder
{
    [field resignFirstResponder];
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

- (NSString*) label
{
    return _label.text;
}

- (void) setLabel:(NSString*)s
{
    if( s )
    {
	if( !_label )
	{
	    _label = [[UILabel alloc] initWithFrame:CGRectZero];
	    [self.contentView addSubview:_label];
	}
	_label.text = s;
    }
    else
	self._label = nil;
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
