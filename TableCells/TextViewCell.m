//
//  TextViewCell.m
//  Glucose
//
//  Created by Brandon Fosdick on 8/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TextViewCell.h"
#import "Constants.h"

@implementation TextViewCell

@synthesize delegate, dirty, font, placeholder, text, view;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if( self = [super initWithStyle:style reuseIdentifier:reuseIdentifier] )
	{
		self.selectionStyle = UITableViewCellSelectionStyleNone;
		view = [[UITextView alloc] initWithFrame:CGRectZero];
//		view.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];

		view.delegate = self;
		[self.contentView addSubview:view];
		[self layoutSubviews];

		dirty = NO;
	}
	return self;
}


- (void)dealloc
{
	[view release];
	[super dealloc];
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	CGRect insetRect = CGRectInset([self.contentView bounds], kCellLeftOffset, 0);
//	CGRect insetRect = CGRectInset([self.contentView bounds], kCellLeftOffset, kCellTopOffset);
	self.view.frame = insetRect;
}

- (void) enablePlaceholder
{
	view.text = placeholder;
	view.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
	view.textColor = [UIColor lightGrayColor];
}

#pragma mark Propertes

- (void) setFont:(UIFont*)f
{
	[font release];
	font = f;
	[font retain];
}

- (void) setText:(NSString*)t
{
	if( t && [t length])
	{
		dirty = YES;
		view.text = t;
		view.font = nil;
		view.textColor = nil;
	}
	else
	{
		dirty = NO;
		[self enablePlaceholder];
	}
	
}

#pragma mark UITextFieldDelegate

- (BOOL) textViewShouldBeginEditing:(UITextView*)textView
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(textViewCellShouldBeginEditing:)])
        return [self.delegate textViewCellShouldBeginEditing:self];
	return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
	if( !dirty && [textView hasText])
	{
		textView.text = nil;	// Clear the placeholder text
		textView.font = nil;	// Set the font and color
		textView.textColor = nil;
	}
    if (self.delegate && [self.delegate respondsToSelector:@selector(textViewCellDidBeginEditing:)])
        return [self.delegate textViewCellDidBeginEditing:self];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
	if( [textView hasText] )
		dirty = YES;
	else
	{
		[self enablePlaceholder];
		dirty = NO;
	}

//    if (self.delegate && [self.delegate respondsToSelector:@selector(textViewCellDidEndEditing:)])
//        [self.delegate textViewCellDidEndEditing:self];
}

@end
