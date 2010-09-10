//
//  LogEntryViewController.h
//  Glucose
//
//  Created by Brandon Fosdick on 6/30/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <sqlite3.h>

#import "CategoryViewController.h"	// For CategoryViewControllerDelegate
#import "DoseFieldCell.h"
#import "InsulinTypeViewController.h"	// For InsulinTypeViewControllerDelegate
#import "NumberFieldCell.h"			// For NumberFieldCellDelegate
#import "TextViewCell.h"
#import "SlidingViewController.h"

@class CategoryViewController;
@class InsulinTypeViewController;
@class LogEntry;
@class LogDay;
@class NumberFieldCell;

@interface LogEntryViewController : SlidingViewController <CategoryViewControllerDelegate, DoseFieldCellDelegate, InsulinTypeViewControllerDelegate, NumberFieldCellDelegate, TextViewCellDelegate>
{
    LogEntry* entry;
    LogDay*		entrySection;

// Private
    CategoryViewController*	categoryViewController;
    InsulinTypeViewController*	insulinTypeViewController;
    NSDateFormatter*	dateFormatter;
    NumberFieldCell*	glucoseCell;
    UITableViewCell*	cellTimestamp;
    BOOL	didSelectRow;
    BOOL	didUndo;
    unsigned	editedIndex;
    BOOL	editingNewEntry;
}

@property (nonatomic, retain) LogEntry* entry;
@property (nonatomic, retain) LogDay* entrySection;
@property (nonatomic, assign) BOOL	editingNewEntry;

- (void)shaken;

@end
