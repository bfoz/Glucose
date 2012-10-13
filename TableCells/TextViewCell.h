//
//  TextViewCell.h
//  Glucose
//
//  Created by Brandon Fosdick on 8/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TextViewCellDelegate;

@interface TextViewCell : UITableViewCell <UITextViewDelegate>
{
	id <TextViewCellDelegate> __unsafe_unretained delegate;
	BOOL	dirty;
	UIFont*	font;
	NSString*	placeholder;
	NSString*	text;
    UITextView*	view;
}

@property (nonatomic, unsafe_unretained) id <TextViewCellDelegate> delegate;
@property (nonatomic, assign)	BOOL	dirty;
@property (nonatomic, strong)	UIFont*	font;
@property (nonatomic, copy)		NSString*	placeholder;
@property (nonatomic, copy)		NSString*	text;
@property (nonatomic, readonly) UITextView*	view;

@end

@protocol TextViewCellDelegate <NSObject>

@optional
- (BOOL)textViewCellShouldBeginEditing:(TextViewCell*)cell;
- (void)textViewCellDidBeginEditing:(TextViewCell*)cell;
//- (void)textViewCellDidEndEditing:(TextViewCell*)cell;

@end
