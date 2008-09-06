//
//  InsulinDose.m
//  Glucose
//
//  Created by Brandon Fosdick on 7/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "InsulinDose.h"
#import "InsulinType.h"

@implementation InsulinDose

@synthesize dose, type;

+ (InsulinDose*)withType:(InsulinType*)t
{
	InsulinDose* n = [[InsulinDose alloc] init];
	n.type = t;
	return n;
}

@end
