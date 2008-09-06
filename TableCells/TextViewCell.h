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
	id <TextViewCellDelegate> delegate;
	BOOL	dirty;
	UIFont*	font;
	NSString*	placeholder;
	NSString*	text;
    UITextView*	view;
}

@property (nonatomic, assign) id <TextViewCellDelegate> delegate;
@property (nonatomic, assign)	BOOL	dirty;
@property (nonatomic, retain)	UIFont*	font;
@property (nonatomic, copy)		NSString*	placeholder;
@property (nonatomic, copy)		NSString*	text;
@property (nonatomic, readonly) UITextView*	view;

@end

@protocol TextViewCellDelegate <NSObject>

// Invoked before editing begins. The delegate may return NO to prevent editing.
- (BOOL)textViewCellShouldBeginEditing:(TextViewCell*)cell;
- (void)textViewCellDidBeginEditing:(TextViewCell*)cell;
//- (void)textViewCellDidEndEditing:(TextViewCell*)cell;

@end
