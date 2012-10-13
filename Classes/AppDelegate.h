
#import <sqlite3.h>

@class InsulinType;
@class LogEntry;
@class LogDay;
@class LogModel;

@class GDataServiceGoogleDocs;

@interface AppDelegate : NSObject <UIApplicationDelegate>
{
    IBOutlet UIWindow *window;
    UINavigationController* navController;

@private
    LogModel*	model;
}

@property (nonatomic, retain)	UIWindow*	window;
@property (nonatomic, retain)	UINavigationController* navController;
@property (nonatomic, readonly) GDataServiceGoogleDocs*	docService;

- (void) appendBundledCategories;
- (void) appendBundledInsulinTypes;
- (void) deleteLogEntriesFrom:(NSDate*)from to:(NSDate*)to;
- (unsigned) numLogEntriesForInsulinTypeID:(unsigned)typeID;
- (unsigned) numLogEntriesFrom:(NSDate*)from to:(NSDate*)to;
- (unsigned) numRowsForCategoryID:(unsigned)catID;
- (NSDate*) earliestLogEntryDate;
- (unsigned) numLogEntries;

@end

extern NSDateFormatter* shortDateFormatter;
extern AppDelegate* appDelegate;

