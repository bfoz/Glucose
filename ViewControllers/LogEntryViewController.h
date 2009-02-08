//
//  LogEntryViewController.h
//  Glucose
//
//  Created by Brandon Fosdick on 6/30/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <sqlite3.h>

#import "DoseFieldCell.h"
#import "NumberFieldCell.h"			// For NumberFieldCellDelegate
#import "TextViewCell.h"
#import "SlidingViewController.h"

@class CategoryViewController;
@class InsulinTypeViewController;
@class LogEntry;
@class LogDay;
@class NumberFieldCell;

@interface LogEntryViewController : SlidingViewController <DoseFieldCellDelegate, NumberFieldCellDelegate, TextViewCellDelegate>
{
    LogEntry* entry;
    LogDay*		entrySection;

// Private
    CategoryViewController*	categoryViewController;
    InsulinTypeViewController*	insulinTypeViewController;
    NSDateFormatter*	dateFormatter;
    NumberFieldCell*	glucoseCell;
    NSIndexPath*	selectedIndexPath;
    UITableViewCell*	cellTimestamp;
    sqlite3*	database;			// SQLite database handle
}

@property (nonatomic, retain) LogEntry* entry;
@property (nonatomic, retain) LogDay* entrySection;

@end
