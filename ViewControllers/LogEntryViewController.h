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
#import "TextFieldCell.h"
#import "TextViewCell.h"
#import "SlidingViewController.h"

@class CategoryViewController;
@class InsulinTypeViewController;
@class LogEntry;

@interface LogEntryViewController : SlidingViewController <DoseFieldCellDelegate, TextViewCellDelegate, TextFieldCellDelegate>
{
	LogEntry* entry;
	NSMutableDictionary*	entrySection;

// Private
	CategoryViewController*	categoryViewController;
	InsulinTypeViewController*	insulinTypeViewController;
    NSDateFormatter*	dateFormatter;
    NSNumberFormatter*	glucoseFormatter;
    NSNumberFormatter*	numberFormatter;
	UITextField*	glucoseTextField;
    UITableView*	tableView;
    NSIndexPath*	selectedIndexPath;
	UITableViewCell*	cellTimestamp;
    sqlite3*	database;			// SQLite database handle
}

@property (nonatomic, retain) LogEntry* entry;
@property (nonatomic, retain) NSMutableDictionary* entrySection;

@end
