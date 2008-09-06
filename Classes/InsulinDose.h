//
//  InsulinDose.h
//  Glucose
//
//  Created by Brandon Fosdick on 7/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class InsulinType;

@interface InsulinDose : NSObject
{
	NSNumber*	dose;
	InsulinType*	type;
}

@property (nonatomic, retain)	NSNumber*	dose;
@property (nonatomic, retain)	InsulinType*	type;

+ (InsulinDose*)withType:(InsulinType*)t;

@end
