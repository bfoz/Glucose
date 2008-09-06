//
//  DualTableViewCell.h
//  Glucose
//
//  Created by Brandon Fosdick on 7/21/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface DualTableViewCell : UITableViewCell
{
	UILabel*	leftLabel;
	UILabel*	rightLabel;
	NSString*	leftText;
	NSString*	rightText;
//	NSString*	leftTextAlignment;
//	NSString*	righttTextAlignment;
}

@property (nonatomic, copy) NSString* leftText;
@property (nonatomic, copy) NSString* rightText;
@property (nonatomic) UITextAlignment leftTextAlignment;
@property (nonatomic) UITextAlignment rightTextAlignment;

@end
