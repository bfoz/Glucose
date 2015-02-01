#import "SpecsHelper.h"
#import "LogViewController.h"

#import "LogModel.h"
#import "LogModel+CoreData.h"
#import "LogModel+SpecHelper.h"
#import "ManagedLogDay+App.h"
#import "ManagedLogDay+SpecHelper.h"
#import "ManagedLogEntry+App.h"
#import "SettingsViewController.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

@interface LogViewController (Specs)
- (void) willEnterForegroundNotification:(NSNotification *)notification;
@end

SPEC_BEGIN(LogViewControllerSpec)

describe(@"LogViewController", ^{
    __block LogViewController* controller;
    __block UINavigationController* navigationController;
    __block LogModel*	logModel;
    __block id mockLogViewDelegate;

    beforeEach(^{
	logModel = [[[LogModel alloc] init] autorelease];
	mockLogViewDelegate = fake_for(@protocol(LogViewDelegate));

	controller = [[[LogViewController alloc] initWithModel:logModel
						      delegate:mockLogViewDelegate] autorelease];

	navigationController = [[[UINavigationController alloc] initWithRootViewController:controller] autorelease];

	controller.view should_not be_nil;
    });

    it(@"should display the correct title", ^{
	controller.navigationItem.title should equal(@"Glucose");
    });

    it(@"should have a proper table view", ^{
	controller.tableView should_not be_nil;
	controller.tableView.style should equal(UITableViewStylePlain);
    });

    it(@"should have a right bar button item", ^{
	controller.navigationItem.rightBarButtonItem should_not be_nil;
    });

    it(@"should have a left bar button item", ^{
	controller.navigationItem.leftBarButtonItem should_not be_nil;
    });

    describe(@"when the Settings button is tapped", ^{
	beforeEach(^{
	    [controller.navigationItem.leftBarButtonItem tap];
	});

	it(@"should flip to the settings view", ^{
	    controller.navigationController.topViewController should be_instance_of([SettingsViewController class]);
	});
    });

    describe(@"when the Add button is tapped", ^{
	beforeEach(^{
	    spy_on(controller.navigationController);

	    [controller.navigationItem.rightBarButtonItem tap];
	});

	it(@"should push a new log entry view controller", ^{
	    controller.navigationController should have_received("pushViewController:animated:");
	});

	it(@"should change the Back button title to Cancel", ^{
	    controller.navigationItem.backBarButtonItem.title should equal(@"Cancel");
	});

	describe(@"when the user saves the new entry", ^{
	    beforeEach(^{
		[controller logEntryView:nil didEndEditingEntry:nil];
	    });

	    it(@"should pop the log entry view controller", ^{
		controller.navigationController.topViewController should_not be_instance_of([LogEntryViewController class]);
	    });
	});
    });

    describe(@"when the model has no log entries", ^{
	beforeEach(^{
	    logModel.numberOfLogDays should equal(0);
	});

	it(@"should have no sections", ^{
	    controller.tableView.numberOfSections should equal(0);
	});
    });

    describe(@"when the model has log entries", ^{
	beforeEach(^{
	    [LogModel setGlucoseUnitsSetting:kGlucoseUnits_mgdL];

	    ManagedLogDay* logDay0 = [logModel insertManagedLogDay];

	    logDay0.date = [NSDate date];
	    [logModel insertManagedLogEntryIntoManagedLogDay:logDay0].glucose = @100;
	    [logModel insertManagedLogEntryIntoManagedLogDay:logDay0].glucose = @200;

	    ManagedLogDay* yesterday = [logModel insertManagedLogDay];
	    yesterday.date = [logDay0.date dateByAddingTimeInterval:-24*60*60];
	    [logModel insertManagedLogEntryIntoManagedLogDay:yesterday].glucose = @100;
	    [logModel insertManagedLogEntryIntoManagedLogDay:yesterday].glucose = @200;

	    ManagedLogDay* logDay1 = [logModel insertManagedLogDay];
	    NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	    dateFormatter.dateStyle = NSDateFormatterMediumStyle;
	    dateFormatter.timeStyle = NSDateFormatterNoStyle;

	    logDay1.date = [dateFormatter dateFromString:@"January 1, 2013"];
	    [logModel insertManagedLogEntryIntoManagedLogDay:logDay1].glucose = @100;
	    [logModel insertManagedLogEntryIntoManagedLogDay:logDay1].glucose = @200;
	    [logModel insertManagedLogEntryIntoManagedLogDay:logDay1].glucose = @300;

	    [logDay0 updateStatistics];
	    [yesterday updateStatistics];
	    [logDay1 updateStatistics];

	    [logModel save];
	});

	it(@"should have 1 section per day", ^{
	    controller.tableView.numberOfSections should equal(3);
	});

	it(@"should have a row for each entry in a section", ^{
	    [controller.tableView numberOfRowsInSection:0] should equal(2);
	    [controller.tableView numberOfRowsInSection:1] should equal(2);
	    [controller.tableView numberOfRowsInSection:2] should equal(3);
	});

	it(@"should have proper section titles", ^{
	    [controller tableView:nil titleForHeaderInSection:0] should equal(@"Today (150 mg/dL)");
	    [controller tableView:nil titleForHeaderInSection:1] should equal(@"Yesterday (150 mg/dL)");
	    [controller tableView:nil titleForHeaderInSection:2] should equal(@"1/1/13 (200 mg/dL)");
	});

	describe(@"when a row is tapped", ^{
	    beforeEach(^{
		spy_on(controller.navigationController);
		[controller tableView:nil didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
	    });

	    it(@"should push a log entry view controller", ^{
		controller.navigationController should have_received("pushViewController:animated:");
	    });
	});
    });

    describe(@"when returning to the foreground the next day", ^{
	beforeEach(^{
	    [LogModel setGlucoseUnitsSetting:kGlucoseUnits_mgdL];

	    ManagedLogDay* today = [logModel insertManagedLogDay];

	    today.date = [NSDate date];
	    [logModel insertManagedLogEntryIntoManagedLogDay:today].glucose = @100;
	    [logModel insertManagedLogEntryIntoManagedLogDay:today].glucose = @200;

	    ManagedLogDay* yesterday = [logModel insertManagedLogDay];
	    yesterday.date = [today.date dateByAddingTimeInterval:-24*60*60];
	    [logModel insertManagedLogEntryIntoManagedLogDay:yesterday].glucose = @100;
	    [logModel insertManagedLogEntryIntoManagedLogDay:yesterday].glucose = @200;

	    [today updateStatistics];
	    [yesterday updateStatistics];

	    [logModel save];

	    // Fake a new day by changing the logDay dates
	    today.date = [today.date dateByAddingTimeInterval:-24*60*60];
	    yesterday.date = [today.date dateByAddingTimeInterval:-24*60*60];
//
//	    [controller willEnterForegroundNotification:nil];
	});

	it(@"should update the section headers", ^{
	    [controller tableView:nil titleForHeaderInSection:0] should equal(@"Yesterday (150 mg/dL)");
	});
    });
});

SPEC_END
