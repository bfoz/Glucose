//
//  DoseFieldCell.m
//  Glucose
//
//  Created by Brandon Fosdick on 7/26/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "DoseFieldCell.h"
#import "InsulinType.h"
#import "Constants.h"

@implementation DoseFieldCell

@synthesize delegate;
@synthesize dose, doseField;

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier])
    {
	self.selectionStyle = UITableViewCellSelectionStyleNone;

	doseField = [[NumberField alloc] initWithFrame:CGRectZero];

	doseField.delegate = self;
	doseField.textAlignment = UITextAlignmentRight;
	doseField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	doseField.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
	doseField.clearButtonMode = UITextFieldViewModeWhileEditing;
	doseField.placeholder = @"Insulin";

	typeField = [[UILabel alloc] initWithFrame:CGRectZero];
	typeField.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];

	self.text = @"New Insulin Dose";
	self.textColor = [UIColor lightGrayColor];
	self.textAlignment = UITextAlignmentCenter;

	[self.contentView addSubview:doseField];
	[self.contentView addSubview:typeField];
	[self layoutSubviews];
    }
    return self;
}

- (void)dealloc
{
    [doseField release];
    [typeField release];
    [super dealloc];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect insetRect = CGRectInset([self.contentView bounds], kCellLeftOffset, 0);

    // If dose has been set, and the dose has a type, display both fields
    //  The doseField will show it's placeholder and the typeField will show the
    //  set type.
    // If no dose has been set, or the dose doesn't have a type, display only
    //  doseField centered in the cell. If no dose value has been set, display
    //  the placeholder
    if( dose && dose.type )
    {
	const unsigned w = (insetRect.size.width - kCellLeftOffset)/2;	
	insetRect.size.width = w;
	doseField.frame  = insetRect;
	insetRect.origin.x += w + kCellLeftOffset;
	typeField.frame  = insetRect;
	doseField.hidden  = NO;
	typeField.hidden = NO;
	[[[self.contentView subviews] objectAtIndex:0] setHidden:YES];
    }
    else
    {
	doseField.hidden  = YES;
	typeField.hidden = YES;
	[[[self.contentView subviews] objectAtIndex:0] setHidden:NO];
    }
    
//    doseField.borderStyle = UITextBorderStyleLine;
}

- (void)setDose:(InsulinDose*)d
{
    // Need to redo layout if dose has changed
    if( dose != d )
	[self setNeedsLayout];

    [dose release];
    dose = d;
    [dose retain];
    
    if( !dose )
	return;

    doseField.number = d.dose;
    // Fake a placeholder type display for the UILabel when no insulin type is set for the row
    if( d && d.type && d.type.shortName && [d.type.shortName length] )
    {
	typeField.text = d.type.shortName;
	typeField.textColor = [UIColor darkTextColor];		
    }
    else
    {
	typeField.text = @"Type";
	typeField.textColor = [UIColor lightGrayColor];
    }
}

#pragma mark UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if( self.delegate && [self.delegate respondsToSelector:@selector(doseDidBeginEditing:)] )
	[self.delegate doseDidBeginEditing:self];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(doseShouldBeginEditing:)])
	return [self.delegate doseShouldBeginEditing:self];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(doseDidEndEditing:)])
        [self.delegate doseDidEndEditing:self];
}
/*
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    if (self.target && [self.target respondsToSelector:@selector(textFieldShouldEndEditing:)])
        return [self.target textFieldShouldEndEditing:textField];
    return YES;
}
 */
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [doseField resignFirstResponder];
    return YES;
}

#pragma mark Propertes

- (int) precision
{
    return doseField.precision;
}

- (void) setPrecision:(int)p
{
    doseField.precision = p;
}

@end
