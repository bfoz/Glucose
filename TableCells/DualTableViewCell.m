//
//  DualTableViewCell.m
//  Glucose
//
//  Created by Brandon Fosdick on 7/21/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "DualTableViewCell.h"
#import "Constants.h"

/*
 // table view cell content offsets
 #define kCellLeftOffset			8.0
 #define kTextFieldHeight		30.0
*/ 
@implementation DualTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if( self = [super initWithStyle:style reuseIdentifier:reuseIdentifier] )
	{
		self.selectionStyle = UITableViewCellSelectionStyleNone;

		// Create the UILabels
		leftLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		rightLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		// Initialization code
		leftLabel.font = rightLabel.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
		[self.contentView addSubview:leftLabel];
		[self.contentView addSubview:rightLabel];
		[self layoutSubviews];
	}
	return self;
}

/*
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

	[super setSelected:selected animated:animated];

	// Configure the view for the selected state
}
*/

- (void)layoutSubviews
{
	[super layoutSubviews];

	CGRect insetRect = CGRectInset([self.contentView bounds], kCellLeftOffset, 0);
	
	const unsigned w = (insetRect.size.width - kCellLeftOffset)/2;
	
	CGRect leftFrame = insetRect;
	leftFrame.size.width = w;
	
	CGRect rightFrame = leftFrame;
	rightFrame.origin.x += w + kCellLeftOffset;

	leftLabel.frame  = leftFrame;
	rightLabel.frame  = rightFrame;
}

- (NSString*)leftText
{
	return leftLabel ? leftLabel.text : nil;
}

- (void)setLeftText:(NSString*)text
{
	if( leftLabel )
		leftLabel.text = text;
}

- (NSString*)rightText
{
	return rightLabel ? rightLabel.text : nil;
}

- (void)setRightText:(NSString*)text
{
	if( rightLabel )
		rightLabel.text = text;
}

- (UITextAlignment)leftTextAlignment
{
	return leftLabel ? leftLabel.textAlignment : (UITextAlignment)nil;
}

- (void)setLeftTextAlignment:(UITextAlignment)a
{
	if( leftLabel )
		leftLabel.textAlignment = a;
}

- (UITextAlignment)rightTextAlignment
{
	return rightLabel ? rightLabel.textAlignment : (UITextAlignment)nil;
}

- (void)setRightTextAlignment:(UITextAlignment)a
{
	if( rightLabel )
		rightLabel.textAlignment = a;
}

@end
