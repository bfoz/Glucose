//
//  InsulinTypeViewController.h
//  Glucose
//
//  Created by Brandon Fosdick on 8/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TextFieldCell.h"

@class AppDelegate;
@class LogEntry;

@interface InsulinTypeViewController : UITableViewController <TextFieldCellDelegate>
{
	AppDelegate*	appDelegate;
	BOOL			dirty;
	TextFieldCell*	editCell;
    LogEntry*		editedObject;
	unsigned		editedIndex;
	CGFloat			keyboardHeight;
	CGFloat			editFieldBottom;
	unsigned		numChecked;
	BOOL			multiCheck;
}

@property (nonatomic, retain) LogEntry* editedObject;
@property (nonatomic, assign) unsigned editedIndex;

- (void) setMultiCheck:(BOOL)e;

@end
