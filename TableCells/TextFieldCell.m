//
//  TextFieldCell.m
//  Glucose
//
//  Created by Brandon Fosdick on 7/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TextFieldCell.h"

// table view cell content offsets
#define kCellLeftOffset			8.0
#define kCellTopOffset			12.0
#define kTextFieldHeight		30.0
#define kTextFieldWidth							100.0	// initial width, but the table cell will dictact the actual width

@implementation TextFieldCell

@synthesize delegate, editedObject, view;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if( self = [super initWithStyle:style reuseIdentifier:reuseIdentifier] )
	{
		self.selectionStyle = UITableViewCellSelectionStyleNone;

		view = [[UITextField alloc] initWithFrame:CGRectZero];
		view.delegate = self;
		[self.contentView addSubview:view];
		[self layoutSubviews];
	}
	return self;
}

- (void)dealloc
{
	[super dealloc];
}
/*
- (void)setView:(UITextField *)inView
{
	view = inView;
	[self.view retain];
	
	view.delegate = self;
	
	[self.contentView addSubview:inView];
	[self layoutSubviews];
}
*/

- (void)layoutSubviews
{
	[super layoutSubviews];

	CGRect insetFrame = CGRectInset([self.contentView bounds], kCellLeftOffset, kCellTopOffset);
	insetFrame.size.height = kTextFieldHeight;
	self.view.frame  = insetFrame;
}

- (void) resignFirstResponder
{
	[view resignFirstResponder];
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(textFieldCellShouldBeginEditing:)])
        return [self.delegate textFieldCellShouldBeginEditing:self];
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	if( self.delegate && [self.delegate respondsToSelector:@selector(textFieldCellDidBeginEditing:)] )
		[self.delegate textFieldCellDidBeginEditing:self];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	// Notify the cell delegate that editing ended.
    if (self.delegate && [self.delegate respondsToSelector:@selector(textFieldCellDidEndEditing:)])
        [self.delegate textFieldCellDidEndEditing:self];
}
/*
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
//    if (self.delegate && [self.delegate respondsToSelector:@selector(textFieldShouldEndEditing:)])
//        return [self.delegate textFieldShouldEndEditing:textField];
	return YES;
}
*/
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [view resignFirstResponder];
    return YES;
}

#pragma mark Propertes

- (UITextFieldViewMode) clearButtonMode
{
	return view.clearButtonMode;
}

- (void) setClearButtonMode:(UITextFieldViewMode)m
{
	view.clearButtonMode = m;
}

- (UIFont*) font
{
	return view.font;
}

- (void) setFont:(UIFont*)f
{
	view.font = f;
}

- (NSString*) placeholder
{
	return view.placeholder;
}

- (void) setPlaceholder:(NSString*)p
{
	view.placeholder = p;
}

- (NSString*) text
{
	return view.text;
}

- (void) setText:(NSString*)t
{
	view.text = t;
}

- (UITextAlignment) textAlignment
{
	return view.textAlignment;
}

- (void) setTextAlignment:(UITextAlignment)a
{
	view.textAlignment = a;
}

@end
