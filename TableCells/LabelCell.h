//
//  LabelCell.h
//  Glucose
//
//  Created by Brandon Fosdick on 11/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LabelCell : UITableViewCell
{
	UILabel*	label;
}

@property (nonatomic, copy)	NSString*	text;

@end
