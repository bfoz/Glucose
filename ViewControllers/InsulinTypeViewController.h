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
    BOOL		didUndo;
    BOOL			dirty;
    BOOL			multiCheck;
    unsigned	    deleteRowNum;
    NSMutableSet*	selectedInsulinTypes;
    enum
    {
	ALERT_REASON_DEFAULT_NEW_ENTRY_TYPE,
	ALERT_REASON_TYPE_NOT_EMPTY
    } alertReason;
}

@property (nonatomic, assign) id <InsulinTypeViewControllerDelegate>   delegate;
@property (nonatomic, assign) BOOL	multiCheck;
@property (nonatomic, readonly) NSMutableSet*	selectedInsulinTypes;

- (void) setMultiCheck:(BOOL)e;
- (void) setSelectedInsulinType:(InsulinType*)type;
- (void) setSelectedInsulinTypes:(NSArray*)types;

@end

@protocol InsulinTypeViewControllerDelegate <NSObject>

@optional
- (void) insulinTypeViewControllerCreateInsulinType;
- (void) insulinTypeViewControllerDidDeleteInsulinType:(InsulinType*)type;
- (void) insulinTypeViewControllerDidEndMultiSelect;
- (BOOL) insulinTypeViewControllerDidSelectInsulinType:(InsulinType*)type;
- (void) insulinTypeViewControllerDidSelectRestoreDefaults;
- (void) insulinTypeViewControllerDidUnselectInsulinType:(InsulinType*)type;

@end
