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
	    [controller.navigationItem.rightBarButtonItem tap];
	});

	it(@"should push a new log entry view controller", ^{
	    controller.navigationController.topViewController should be_instance_of([LogEntryViewController class]);
	});

	it(@"should put the log entry view controller in edit mode", ^{
	    LogEntryViewController* logEntryViewController = (LogEntryViewController*)controller.navigationController.topViewController;
	    logEntryViewController.editingNewEntry should be_truthy;
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

	it(@"should have a single empty Today section", ^{
	    controller.tableView.numberOfSections should equal(1);
	    [controller.tableView numberOfRowsInSection:0] should equal(0);
	});

	it(@"should have a proper section title", ^{
	    [controller tableView:nil titleForHeaderInSection:0] should equal(@"Today");
	});
    });

    describe(@"when the model has log entries", ^{
	beforeEach(^{
	    [LogModel setGlucoseUnitsSetting:kGlucoseUnits_mgdL];

	    ManagedLogDay* logDay0 = [logModel insertManagedLogDay];

	    logDay0.date = [NSDate date];
	    [logModel insertManagedLogEntryIntoManagedLogDay:logDay0].glucose = @100;
	    [logModel insertManagedLogEntryIntoManagedLogDay:logDay0].glucose = @200;

	    ManagedLogDay* logDay1 = [logModel insertManagedLogDay];
	    NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	    dateFormatter.dateStyle = NSDateFormatterMediumStyle;
	    dateFormatter.timeStyle = NSDateFormatterNoStyle;

	    logDay1.date = [dateFormatter dateFromString:@"January 1, 2013"];
	    [logModel insertManagedLogEntryIntoManagedLogDay:logDay1].glucose = @100;
	    [logModel insertManagedLogEntryIntoManagedLogDay:logDay1].glucose = @200;
	    [logModel insertManagedLogEntryIntoManagedLogDay:logDay1].glucose = @300;

	    [logDay0 updateStatistics];
	    [logDay1 updateStatistics];

	    [logModel save];
	});

	it(@"should have 1 section per day", ^{
	    controller.tableView.numberOfSections should equal(2);
	});

	it(@"should have a row for each entry in a section", ^{
	    [controller.tableView numberOfRowsInSection:0] should equal(2);
	    [controller.tableView numberOfRowsInSection:1] should equal(3);
	});

	it(@"should have proper section titles", ^{
	    [controller tableView:nil titleForHeaderInSection:0] should equal(@"Today (150 mg/dL)");
	    [controller tableView:nil titleForHeaderInSection:1] should equal(@"1/1/13 (200 mg/dL)");
	});

	describe(@"when a row is tapped", ^{
	    beforeEach(^{
		[controller tableView:nil didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
	    });

	    it(@"should push a log entry view controller", ^{
		controller.navigationController.topViewController should be_instance_of([LogEntryViewController class]);
	    });

	    it(@"should not put the log entry view controller in edit mode", ^{
		LogEntryViewController* logEntryViewController = (LogEntryViewController*)controller.navigationController.topViewController;
		logEntryViewController.editingNewEntry should_not be_truthy;
	    });
	});
    });
});

SPEC_END
