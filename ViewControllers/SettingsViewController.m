//
//  SettingsViewController.m
//  Glucose
//
//  Created by Brandon Fosdick on 8/23/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "Constants.h"

#import "CategoryViewController.h"
#import "ExportViewController.h"
#import "InsulinTypeViewController.h"
#import "LogModel.h"
#import "LogViewController.h"
#import "NumberField.h"
#import "PurgeViewController.h"
#import "SettingsViewController.h"

#define	URL_PROJECT_PAGE    @"http://bfoz.github.com/Glucose/"

@implementation SettingsViewController

@synthesize delegate;
@synthesize model;

enum Sections
{
    kSectionExportPurge = 0,
    kSectionCategoriesTypes,
    kSectionThresholdsUnits,
    kSectionAbout,
    NUM_SECTIONS
};

enum ExportPurgeRows
{
    kExportRow = 0,
    kPurgeRow,
    NUM_EXPORTPURGE_ROWS
};

enum CategoriesTypesRows
{
    kCategoryRow = 0,
    kInsulinTypeRow,
    kDefaultInsulinRow,
    kFractionalInsulin,
    NUM_CATEGORIESTYPES_ROWS
};

enum ThresholdsUnitsRows
{
    kGlucoseUnitsRow = 0,
    kHighGlucoseWarningRow,
    kLowGlucoseWarningRow,
    NUM_THRESHOLDUNITS_ROWS
};

enum AboutSectionRows
{
    kWriteReviewRow = 0,
    kWebsiteRow,
    kAuthorRow,
    NUM_ABOUT_ROWS
};

- (id)initWithStyle:(UITableViewStyle)style
{
    if( self = [super initWithStyle:style] )
    {
	NSUserDefaults *const defaults = [NSUserDefaults standardUserDefaults];
	const BOOL mgdL = [[defaults objectForKey:kDefaultGlucoseUnits] isEqualToString:kGlucoseUnits_mgdL];

	highGlucoseWarningKey = mgdL ? kHighGlucoseWarning0 : kHighGlucoseWarning1;
	lowGlucoseWarningKey = mgdL ? kLowGlucoseWarning0 : kLowGlucoseWarning1;

/*
        UIButton* b = [UIButton buttonWithType:UIButtonTypeInfoLight];
		[b addTarget:self action:@selector(showSettings:) forControlEvents:UIControlEventTouchUpInside];
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:b];
		[b release];
 */
    }
    return self;
}

- (void) viewDidLoad
{
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
    self.title = @"Settings";
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)dealloc
{
    [defaultInsulinTypeViewController release];
    [exportViewController release];
    [purgeViewController release];
    [super dealloc];
}

- (void) doneAction:(id)sender
{
    // Cancel edit mode in case the controllers are reused later
    [categoryViewController setEditing:NO animated:NO];	
    [insulinTypeViewController setEditing:NO animated:NO];
    [insulinTypeViewController setMultiCheck:NO];

    // Persist changes to NSUserDefaults
    [model flushInsulinTypesForNewEntries];
    [[NSUserDefaults standardUserDefaults] synchronize];

    if( delegate && [delegate respondsToSelector:@selector(settingsViewControllerDidPressBack)] )
	[delegate settingsViewControllerDidPressBack];
}

- (void) glucoseUnitsAction:(UISegmentedControl*)sender
{
    NSUserDefaults *const defaults = [NSUserDefaults standardUserDefaults];
    switch( sender.selectedSegmentIndex )
    {
	case 0:
	    [defaults setObject:kGlucoseUnits_mgdL forKey:kDefaultGlucoseUnits];
	    highGlucoseWarningKey = kHighGlucoseWarning0;
	    lowGlucoseWarningKey = kLowGlucoseWarning0;
	    highGlucoseWarningField.precision = 0;
	    lowGlucoseWarningField.precision = 0;
	    break;
	case 1:
	    [defaults setObject:kGlucoseUnits_mmolL forKey:kDefaultGlucoseUnits];
	    highGlucoseWarningKey = kHighGlucoseWarning1;
	    lowGlucoseWarningKey = kLowGlucoseWarning1;
	    highGlucoseWarningField.precision = 1;
	    lowGlucoseWarningField.precision = 1;
	    break;
    }
    highGlucoseWarningField.text = [defaults stringForKey:highGlucoseWarningKey];
    lowGlucoseWarningField.text = [defaults stringForKey:lowGlucoseWarningKey];
    // Force the LogViewController to reload the LogEntryViewController so it can pick up the change
    appDelegate.logViewController.logEntryViewController = nil;
}

- (void) fractionalInsulinAction:(UISwitch*)sender
{
    NSUserDefaults *const defaults = [NSUserDefaults standardUserDefaults];
    if( sender.on )
    {
	[defaults setObject:[NSNumber numberWithInt:1] forKey:kDefaultInsulinPrecision];
    }
    else
    {
	[defaults setObject:[NSNumber numberWithInt:0] forKey:kDefaultInsulinPrecision];	
    }
    // Force the LogViewController to reload the LogEntryViewController so it can pick up the change
    appDelegate.logViewController.logEntryViewController = nil;
}

#pragma mark -
#pragma mark <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return NUM_SECTIONS;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch( section )
    {
	case kSectionExportPurge:	return NUM_EXPORTPURGE_ROWS;
        case kSectionCategoriesTypes:	return NUM_CATEGORIESTYPES_ROWS;
	case kSectionThresholdsUnits:	return NUM_THRESHOLDUNITS_ROWS;
	case kSectionAbout:		return NUM_ABOUT_ROWS;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    static NSString *cellID = @"CellID";
    
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:cellID];
    if( !cell )
    {
	cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID] autorelease];
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    // Default all rows to bold, black and label-sized
    cell.textLabel.textColor = [UIColor darkTextColor];
    cell.textLabel.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
    cell.textLabel.textAlignment = UITextAlignmentLeft;

    const unsigned section = indexPath.section;
    const unsigned row = indexPath.row;
    switch( section )
    {
	case kSectionExportPurge:
	    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	    switch( row )
	    {
		case kExportRow:    cell.textLabel.text = @"Export"; break;
		case kPurgeRow:	    cell.textLabel.text = @"Purge"; break;
	    }
	    break;
	case kSectionCategoriesTypes:
	    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	    switch( row )
	    {
		case kCategoryRow:	    cell.textLabel.text = @"Categories"; break;
		case kInsulinTypeRow:	    cell.textLabel.text = @"Insulin Types"; break;
		case kDefaultInsulinRow:    cell.textLabel.text = @"Insulins for New Entries"; break;
		case kFractionalInsulin:
		    cell.textLabel.text = @"Fractional Insulin";
		    UISwitch* s = [[UISwitch alloc] initWithFrame:CGRectZero];
		    [s addTarget:self action:@selector(fractionalInsulinAction:) forControlEvents:UIControlEventValueChanged];
		    s.on = [[[NSUserDefaults standardUserDefaults] objectForKey:kDefaultInsulinPrecision] boolValue];
		    cell.accessoryView = s;
		    break;
	    }
	    break;
	case kSectionThresholdsUnits:
	{	    
	    NumberField* f;
	    NSUserDefaults *const defaults = [NSUserDefaults standardUserDefaults];
	    const BOOL mgdL = [[defaults objectForKey:kDefaultGlucoseUnits] isEqualToString:kGlucoseUnits_mgdL];
	    if( row )
	    {
		f = [[NumberField alloc] initWithFrame:CGRectMake(0, kCellTopOffset*2, 50, 20)];
		f.delegate = self;
		f.precision = mgdL ? 0 : 1;
		f.textAlignment = UITextAlignmentRight;
		cell.accessoryView = f;
	    }
	    switch( row )
	    {
		case kHighGlucoseWarningRow:
		    cell.textLabel.text = @"High Glucose Warning";
		    f.text = [defaults stringForKey:highGlucoseWarningKey];
		    f.textColor = [UIColor blueColor];
		    highGlucoseWarningCell = cell;
		    highGlucoseWarningField = f;
		    break;
		case kLowGlucoseWarningRow:
		    cell.textLabel.text = @"Low Glucose Warning";
		    f.text = [defaults stringForKey:lowGlucoseWarningKey];
		    f.textColor = [UIColor redColor];
		    lowGlucoseWarningCell = cell;
		    lowGlucoseWarningField = f;
		    break;
		case kGlucoseUnitsRow:
		    cell.textLabel.text = @"Glucose Units";
		    UISegmentedControl* s = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:kGlucoseUnits_mgdL,kGlucoseUnits_mmolL,nil]];
		    s.segmentedControlStyle = UISegmentedControlStyleBar;
		    [s addTarget:self action:@selector(glucoseUnitsAction:) forControlEvents:UIControlEventValueChanged];
		    s.selectedSegmentIndex = mgdL ? 0 : 1;
		    cell.accessoryView = s;
		    break;
	    }
	} break;
        case kSectionAbout:
	    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	    switch( row )
	    {
		case kAuthorRow:
		    cell.textLabel.text = @"Report a Bug";
		    break;
		case kWebsiteRow:
		    cell.textLabel.text = @"More Information";
		    break;
		case kWriteReviewRow:
		    cell.textLabel.text = @"Write a Review";
		    break;
	    }
	    break;
    }

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if( kSectionAbout == section )
	return @"Copyright 2008-2011 Brandon Fosdick";
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if( kSectionAbout == section )
    {
	NSBundle *const mainBundle = [NSBundle mainBundle];
	NSString *const v = [mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
	NSString *const n = [mainBundle objectForInfoDictionaryKey:@"CFBundleName"];
	return [NSString stringWithFormat:@"%@ v%@", n, v];
    }
    return nil;
}

#pragma mark -
#pragma mark <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    const unsigned section = indexPath.section;
    const unsigned row = indexPath.row;
    switch( section )
    {
	case kSectionExportPurge:
	    switch( row )
	    {
		case kExportRow:
		    if( !exportViewController )
		    {
			exportViewController = [[ExportViewController alloc] initWithStyle:UITableViewStyleGrouped];
			exportViewController.model = model;
		    }
		    [self.navigationController pushViewController:exportViewController animated:YES];
		    break;
		case kPurgeRow:
		    if( !purgeViewController )
			purgeViewController = [[PurgeViewController alloc] initWithStyle:UITableViewStyleGrouped];
		    [self.navigationController pushViewController:purgeViewController animated:YES];
		    break;
	    }
	    break;
	case kSectionCategoriesTypes:
	    switch( row )
	    {
		case kCategoryRow:
		    if( !categoryViewController )	// Get the view controller from appDelegate
		    {
			categoryViewController = [[CategoryViewController alloc] initWithStyle:UITableViewStyleGrouped];
			categoryViewController.delegate = self;
			categoryViewController.model = model;
		    }
		    [self.navigationController pushViewController:categoryViewController animated:YES];
		    // Set editing mode after pushing the view controller. The UITableView doesn't exist
		    //  until loadView has been called. Until then, there's nothing to set editing mode on.
		    [categoryViewController setEditing:YES animated:NO];
		    break;
		case kInsulinTypeRow:
		    if( !insulinTypeViewController )
		    {
			insulinTypeViewController = [[InsulinTypeViewController alloc] initWithStyle:UITableViewStyleGrouped];
			insulinTypeViewController.delegate = self;
			insulinTypeViewController.model = model;
			[insulinTypeViewController setMultiCheck:NO];
		    }
		    [self.navigationController pushViewController:insulinTypeViewController animated:YES];
		    // Set editing mode after pushing the view controller. The UITableView doesn't exist
		    //  until loadView has been called. Until then, there's nothing to set editing mode on.
		    [insulinTypeViewController setEditing:YES animated:NO];
		    break;
		case kDefaultInsulinRow:
		    if( !defaultInsulinTypeViewController )
		    {
			defaultInsulinTypeViewController = [[InsulinTypeViewController alloc] initWithStyle:UITableViewStyleGrouped];
			defaultInsulinTypeViewController.delegate = self;
			defaultInsulinTypeViewController.model = model;
			defaultInsulinTypeViewController.title = @"Default Insulin Types";
			defaultInsulinTypeViewController.multiCheck = YES;
		    }
		    [defaultInsulinTypeViewController setSelectedInsulinTypes:model.insulinTypesForNewEntries];
		    [self.navigationController pushViewController:defaultInsulinTypeViewController animated:YES];
		    break;
	    }
	    break;
	case kSectionThresholdsUnits:
	    switch( row )
	    {
		case kHighGlucoseWarningRow:
		    [highGlucoseWarningField becomeFirstResponder];
		    break;
		case kLowGlucoseWarningRow:
		    [lowGlucoseWarningField becomeFirstResponder];
		    break;
	    }
	    break;
	case kSectionAbout:
	    switch( row )
	    {
		case kAuthorRow:
		{
		    // Is the device configured for email?
		    if( [MFMailComposeViewController canSendMail] )
		    {
			MFMailComposeViewController *mail = [[MFMailComposeViewController alloc] init];
			mail.mailComposeDelegate = self;

			NSBundle *const mainBundle = [NSBundle mainBundle];
			NSString *const v = [mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
			NSString *const n = [mainBundle objectForInfoDictionaryKey:@"CFBundleName"];
			UIDevice *const device = [UIDevice currentDevice];
			[mail setSubject:[NSString stringWithFormat:@"%@ v%@ on %@ %@", n, v, device.model, device.systemVersion]];

			// Set up the recipients.
			NSArray *toRecipients = [NSArray arrayWithObjects:@"bfoz@bfoz.net", nil];
			[mail setToRecipients:toRecipients];

			// Present the mail composition interface.
			[self presentModalViewController:mail animated:YES];
			[mail release];	// Can safely release the controller now.
		    }
		    else
		    {
			// Inform the user that email needs to be configured
			[[[UIAlertView alloc] initWithTitle:@"Error"
						    message:@"Email is not configured on this device. Please configure email in the Settings application."
						   delegate:nil
					  cancelButtonTitle:@"OK"
					  otherButtonTitles:nil] show];
		    }
		}
		break;
		case kWebsiteRow:
		    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:URL_PROJECT_PAGE]];
		    break;
		case kWriteReviewRow:
		    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=294296711"]];
		    break;
	    }
	    break;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

#pragma mark -
#pragma mark <UITextFieldDelegate>

- (UITableViewCell*) cellForField:(UITextField*)field
{
    if( field == highGlucoseWarningField )
	return highGlucoseWarningCell;
    else if( field == lowGlucoseWarningField )
	return lowGlucoseWarningCell;
    return nil;
}

- (SEL) selectorForField:(UITextField*)field
{
    if( field == highGlucoseWarningField )
	return @selector(saveHighGlucoseWarningAction);
    else if( field == lowGlucoseWarningField )
	return @selector(saveLowGlucoseWarningAction);
    return nil;
}

- (void)textFieldDidBeginEditing:(UITextField*)field
{
    [self didBeginEditing:[self cellForField:field] field:field action:[self selectorForField:field]];
}

- (void)saveHighGlucoseWarningAction
{
    [[NSUserDefaults standardUserDefaults] setObject:[editField text] forKey:highGlucoseWarningKey];
    [self saveAction];
}

- (void)saveLowGlucoseWarningAction
{
    [[NSUserDefaults standardUserDefaults] setObject:[editField text] forKey:lowGlucoseWarningKey];
    [self saveAction];
}

#pragma mark -
#pragma mark <CategoryViewControllerDelegate>

- (void) categoryViewControllerCreateCategory
{
    [model addCategory:nil];
}

- (void) categoryViewControllerDidDeleteCategory:(Category*)category
{
    // Purge the record from the database and the categories array
    [model purgeCategory:category];
}

- (void) categoryViewControllerDidSelectRestoreDefaults
{
    [appDelegate appendBundledCategories];    // Restore the missing defaults
}

#pragma mark -
#pragma mark <InsulinTypeViewControllerDelegate>

- (void) insulinTypeViewControllerCreateInsulinType
{
    [model addInsulinTypeWithName:nil];
}

- (void) insulinTypeViewControllerDidDeleteInsulinType:(InsulinType*)type;
{
    [model purgeInsulinType:type];
}

- (void) insulinTypeViewControllerDidEndMultiSelect
{
    [model flushInsulinTypesForNewEntries];
}

- (BOOL) insulinTypeViewControllerDidSelectInsulinType:(InsulinType*)type
{
    if( [model.insulinTypesForNewEntries count] >= 2 )
	return NO;
    [model addInsulinTypeForNewEntries:type];
    return YES;
}

- (void) insulinTypeViewControllerDidSelectRestoreDefaults
{
    [appDelegate appendBundledInsulinTypes];	// Restore the missing defaults
}

- (void) insulinTypeViewControllerDidUnselectInsulinType:(InsulinType*)type
{
    [model removeInsulinTypeForNewEntries:type];
}

#pragma mark -
#pragma mark <MFMailComposeViewControllerDelegate>

- (void) mailComposeController:(MFMailComposeViewController*) controller
	   didFinishWithResult:(MFMailComposeResult) result
			 error:(NSError*) error
{
    [self dismissModalViewControllerAnimated:YES];
}

@end

