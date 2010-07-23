//
//  InsulinTypeViewController.h
//  Glucose
//
//  Created by Brandon Fosdick on 8/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SlidingViewController.h"
#import "TextFieldCell.h"	// Needed for TextFieldCellDelegate

@class LogEntry;
@class TextFieldCell;

@protocol InsulinTypeViewControllerDelegate;

@interface InsulinTypeViewController : SlidingViewController <TextFieldCellDelegate, UIAlertViewDelegate>
{
    id <InsulinTypeViewControllerDelegate>  delegate;
    BOOL			dirty;
    LogEntry*		editedObject;
    unsigned		editedIndex;
    BOOL			multiCheck;
    unsigned	    deleteRowNum;
    enum
    {
	ALERT_REASON_DEFAULT_NEW_ENTRY_TYPE,
	ALERT_REASON_TYPE_NOT_EMPTY
    } alertReason;
}

@property (nonatomic, assign) id <InsulinTypeViewControllerDelegate>   delegate;
@property (nonatomic, retain) LogEntry* editedObject;
@property (nonatomic, assign) unsigned editedIndex;

- (void) setMultiCheck:(BOOL)e;

@end

@protocol InsulinTypeViewControllerDelegate <NSObject>

@optional
- (BOOL) insulinTypeViewControllerDidSelectInsulinType:(InsulinType*)type;
- (void) insulinTypeViewControllerDidUnselectInsulinType:(InsulinType*)type;

@end
