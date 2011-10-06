//
//  LogEntryCell.m
//  Glucose
//
//  Created by Brandon Fosdick on 8/11/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "LogEntryCell.h"
#import "Constants.h"

unsigned categoryNameWidth = 0;
unsigned insulinTypeShortNameWidth = 0;

@implementation LogEntryCell

@synthesize	labelCategory, labelDose0, labelDose1, labelGlucose, labelTimestamp, labelType0, labelType1;

+ (void) setCategoryNameWidth:(unsigned)width
{
    categoryNameWidth = width;
}

+ (void) setInsulinTypeShortNameWidth:(unsigned)width
{
    insulinTypeShortNameWidth = width;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if( self = [super initWithStyle:style reuseIdentifier:reuseIdentifier] )
	{
		self.selectionStyle = UITableViewCellSelectionStyleNone;
		
		labelCategory = [[UILabel alloc] initWithFrame:CGRectZero];
		[self.contentView addSubview:labelCategory];
		labelCategory.textAlignment = UITextAlignmentLeft;
		labelCategory.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];

		labelDose0 = [[UILabel alloc] initWithFrame:CGRectZero];
		[self.contentView addSubview:labelDose0];
		labelDose0.textAlignment = UITextAlignmentRight;
		labelDose0.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
		
		labelDose1 = [[UILabel alloc] initWithFrame:CGRectZero];
		[self.contentView addSubview:labelDose1];
		labelDose1.textAlignment = UITextAlignmentRight;
		labelDose1.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
		
		labelGlucose = [[UILabel alloc] initWithFrame:CGRectZero];
		[self.contentView addSubview:labelGlucose];
		labelGlucose.textAlignment = UITextAlignmentCenter;
		labelGlucose.font = [UIFont boldSystemFontOfSize:[UIFont buttonFontSize]];

		labelTimestamp = [[UILabel alloc] initWithFrame:CGRectZero];
		[self.contentView addSubview:labelTimestamp];
		labelTimestamp.textAlignment = UITextAlignmentLeft;
		labelTimestamp.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];

		labelType0 = [[UILabel alloc] initWithFrame:CGRectZero];
		[self.contentView addSubview:labelType0];
		labelType0.textAlignment = UITextAlignmentLeft;
		labelType0.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];

		labelType1 = [[UILabel alloc] initWithFrame:CGRectZero];
		[self.contentView addSubview:labelType1];
		labelType1.textAlignment = UITextAlignmentLeft;
		labelType1.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
	}
	return self;
}

- (void)dealloc
{
	[labelCategory release];
	[labelDose0 release];
	[labelDose1 release];
	[labelGlucose release];
	[labelNote release];
	[labelTimestamp release];
	[labelType0 release];
	[labelType1 release];
	[super dealloc];
}

// If the cell's entry has a Note field, but...
//	insulin, glucose		don't display note
//	no insulin, glucose		don't display note
//	insulin, no glucose		don't display note
//	no insulin, no glucose	display note
- (void)layoutSubviews
{
	[super layoutSubviews];
	
	CGRect contentRect = [self.contentView bounds];
	CGRect insetRect = CGRectInset(contentRect, kCellLeftOffset, 0);

//	NSLog(@"%f x %f\n", contentRect.size.width, contentRect.size.height);
	const unsigned width = insetRect.size.width;	// Available width
	const unsigned height = insetRect.size.height;	// Available height
//	NSLog(@"%d x %d\n", width, height);
	const unsigned h = height/2;

	// Start
	const unsigned y0 = insetRect.origin.y;
	const unsigned y1 = y0 + h;

	// Width of the Category/Timestamp column
    const unsigned w0 = categoryNameWidth > 80 ? categoryNameWidth : 80;
//	const unsigned w1 = (width - w0)/2;
//	const unsigned w1 = width/3;
//	const unsigned w2 = w1/2-10;
	const unsigned w2 = 30;
//	const unsigned w2 = width/6;
    const unsigned w3 = insulinTypeShortNameWidth;
//	const unsigned w3 = width - (w0 + w1 + w2);

	const unsigned x0 = insetRect.origin.x;
//	const unsigned x2 = x0 + w0 + w1;	// Left origin of column 2
    const unsigned x3 = insetRect.origin.x + insetRect.size.width - insulinTypeShortNameWidth;
	const unsigned x2 = x3 - w2 - 3;	// Left origin of column 2
//	const unsigned x3 = x2 + w2 + 3;

	// Column 0 - Category/Timestamp
	labelTimestamp.frame = CGRectMake(x0, y0, w0, h);
	labelCategory.frame  = CGRectMake(x0, y1, w0, h);

	if( labelNote && !labelGlucose.text && !labelDose0.text && !labelDose1.text )
	{
		// Column 1 - Note (fills remaining width)
		labelNote.frame = CGRectMake(x0 + w0, y0, width - w0, height);
		labelGlucose.hidden = YES;
		labelDose0.hidden = YES;
		labelDose1.hidden  = YES;
		labelType0.hidden = YES;
		labelType1.hidden  = YES;
//		labelNote.backgroundColor = [UIColor lightGrayColor];
	}
	else
	{
		// Column 1 - Glucose (fills remaining width)
		labelGlucose.frame = CGRectMake(x0 + w0, y0, width - w3 - w2 - w0, height);

		CGRect dose0 = CGRectMake(x2, y0, w2, h);
		CGRect type0 = CGRectMake(x3, y0, w3, h);

		if( labelDose0.text && labelType0.text )
		{
			// Column 2 - Insulin values
			labelDose0.frame = dose0;
			labelDose1.frame  = CGRectMake(x2, y1, w2, h);
			// Column 3 - Insulin Types
			labelType0.frame = type0;
			labelType1.frame  = CGRectMake(x3, y1, w3, h);

			labelDose0.hidden = NO;
			labelType0.hidden = NO;
		}
		else	// Move the second dose up one slot if the first dose is empty
		{
			labelDose1.frame  = dose0;
			labelType1.frame = type0;
			labelDose0.hidden = YES;
			labelType0.hidden = YES;
		}
		
		labelGlucose.hidden = NO;
		labelDose1.hidden  = NO;
		labelType1.hidden  = NO;
	}
/*
	labelGlucose.backgroundColor = [UIColor lightGrayColor];
	labelType1.backgroundColor = [UIColor cyanColor];
	labelDose0.backgroundColor = [UIColor magentaColor];
	labelTimestamp.backgroundColor = [UIColor yellowColor];
*/
}

#pragma mark -
#pragma mark Properties

- (NSString*) note
{
	if( labelNote )
		return labelNote.text;
	return nil;
}

- (void) setNote:(NSString*)t
{
	const BOOL a = t && [t length];
	// Lazily create a UILabel, but only if a non-nil, non-empty string is given
	if( !labelNote && a )
	{
		labelNote = [[UILabel alloc] initWithFrame:CGRectZero];
		[self.contentView addSubview:labelNote];
		labelNote.textAlignment = UITextAlignmentLeft;
		[self setNeedsLayout];
	}
	if( labelNote )
	{
		if( a )
			labelNote.text = t;
		else
		{	// Delete the UILabel if a nil, or empty, string is given
			[labelNote removeFromSuperview];
			[labelNote release];
			labelNote = nil;
			[self setNeedsLayout];
		}
	}
}

@end
