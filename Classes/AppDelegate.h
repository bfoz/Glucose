//
//  AppDelegate.h
//  Glucose
//
//  Created by Brandon Fosdick on 6/27/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <sqlite3.h>

@class Category;
@class CategoryViewController;
@class InsulinType;
@class InsulinTypeViewController;
@class LogEntry;
@class LogDay;
@class LogViewController;

@class GDataServiceGoogleDocs;

@interface AppDelegate : NSObject <UIApplicationDelegate>
{
    IBOutlet UIWindow *window;
    UINavigationController* navController;
    NSMutableArray* categories;
	CategoryViewController*	categoryViewController;
    NSMutableArray* defaultInsulinTypes;
    NSMutableArray* insulinTypes;
	InsulinTypeViewController*	insulinTypeViewController;
	LogViewController*	logViewController;
	NSMutableArray* sections;
    sqlite3*	database;			// SQLite database handle
}

@property (nonatomic, retain)	UIWindow*	window;
@property (nonatomic, retain)	UINavigationController* navController;
@property (nonatomic, readonly)	NSMutableArray*		categories;
@property (nonatomic, readonly)	CategoryViewController*	categoryViewController;
@property (nonatomic, readonly)	NSMutableArray*		defaultInsulinTypes;
@property (nonatomic, readonly)	NSMutableArray*		insulinTypes;
@property (nonatomic, readonly)	InsulinTypeViewController*	insulinTypeViewController;
@property (nonatomic, readonly)	LogViewController*	logViewController;
@property (nonatomic, readonly)	NSMutableArray*		sections;
@property (nonatomic, readonly)	sqlite3*		database;
@property (nonatomic, readonly) GDataServiceGoogleDocs*	docService;

#pragma mark Array Management
- (Category*) findCategoryForID:(unsigned)categoryID;
- (InsulinType*) findInsulinTypeForID:(unsigned)typeID;

- (BOOL) deleteLogEntry:(LogEntry*)entry fromSection:(LogDay*)section;
- (LogDay*) findSectionForDate:(NSDate*)date;
- (LogDay*) getSectionForDate:(NSDate*)date;

// Create a new log entry in response to a button press
- (void) addLogEntry:(id)sender;
- (void) deleteCategoryID:(unsigned)path;
- (void) deleteEntriesForCategoryID:(unsigned)categoryID;
- (BOOL) deleteLogEntryAtIndexPath:(NSIndexPath*)indexPath;

- (void) addCategory:(NSString*)name;
- (void) purgeCategoryAtIndex:(unsigned)index;
- (void) removeCategoryAtIndex:(unsigned)index;
- (void) flushCategories;
- (void) deleteLogEntriesFrom:(NSDate*)from to:(NSDate*)to;
- (unsigned) numLogEntriesFrom:(NSDate*)from to:(NSDate*)to;
- (unsigned) numRowsForCategoryID:(NSInteger)catID;
- (NSDate*) earliestLogEntryDate;
- (unsigned) numLogEntries;
- (void) updateCategory:(Category*)c;
- (void) updateCategoryNameMaxWidth;

- (void) addInsulinType:(NSString*)name;
- (void) purgeInsulinTypeAtIndex:(unsigned)index;
- (void) flushInsulinTypes;
- (void) flushDefaultInsulinTypes;
- (void) removeDefaultInsulinType:(InsulinType*)type;
- (void) removeInsulinTypeAtIndex:(unsigned)index;
- (void) updateInsulinType:(InsulinType*)type;
- (void) updateInsulinTypeShortNameMaxWidth;

// Google Docs
- (void) setUserCredentialsWithUsername:(NSString*)user password:(NSString*)pass;

@end

extern unsigned maxCategoryNameWidth;
extern unsigned maxInsulinTypeShortNameWidth;
extern NSDateFormatter* shortDateFormatter;

