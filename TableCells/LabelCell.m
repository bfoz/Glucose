//
//  LabelCell.m
//  Glucose
//
//  Created by Brandon Fosdick on 11/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Constants.h"

#import "LabelCell.h"

@implementation LabelCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if( self = [super initWithStyle:style reuseIdentifier:reuseIdentifier] )
	{
		label = [[UILabel alloc] initWithFrame:CGRectZero];
		label.numberOfLines = 0;
		[self.contentView addSubview:label];
    }
    return self;
}

- (void)dealloc
{
	[label dealloc];
    [super dealloc];
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	label.frame = CGRectInset([self.contentView bounds], kCellLeftOffset, kCellTopOffset);
}

#pragma mark Propertes

- (NSString*) text
{
	return label.text;
}

- (void) setText:(NSString*)t
{
	label.text = t;
}

@end
