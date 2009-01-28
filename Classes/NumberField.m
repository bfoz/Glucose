//
//  NumberField.m
//  Glucose
//
//  Created by Brandon Fosdick on 1/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NumberField.h"

@interface NumberField ()
@property (nonatomic, retain)	NSMutableString*    input;
@end

@implementation NumberField

@synthesize input, precision;

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
	self.keyboardType = UIKeyboardTypeNumberPad;
    }
    return self;
}

- (void)dealloc
{
    [input release];
    [super dealloc];
}

- (BOOL)fieldEditor:(id)fp8 shouldInsertText:(id)string replacingRange:(struct _NSRange)range
{
    // Behave normally if not using fractional digits
    if( !precision )
	return YES;

    if( input.length )
    {
	// range.length is only non-zero when deleting characters
	if( range.length )
	    [input deleteCharactersInRange:NSMakeRange(input.length-range.length, range.length)];
	else
	    [input appendString:string];
    }
    else if( 0 == range.length )
	self.input = [NSMutableString stringWithString:string];
    else
	return YES;	// Nothing to do if deleting from nil/empty input

    const int i = input.length - 1;
    if( i > 0 )
	super.text = [NSString stringWithFormat:@"%@.%@", [input substringToIndex:i], [input substringFromIndex:i]];
    else if( i == 0 )
	super.text = [NSString stringWithFormat:@"0.%@", input];
    else
	super.text = nil;
    
    return NO;
}

- (void)_clearButtonClicked:(id)fp8
{
    self.input = nil;
    [super _clearButtonClicked:fp8];
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
    if( [n floatValue] )
	self.text = [NSString localizedStringWithFormat:@"%.*f", precision, [n floatValue]];
    else
	self.text = nil;
}

- (void) setText:(NSString*)t
{
    self.input = t ? [NSMutableString stringWithString:t] : nil;
    [input replaceOccurrencesOfString:@"." withString:@"" options:0 range:NSMakeRange(0, input.length)];
    super.text = t;
}

@end
