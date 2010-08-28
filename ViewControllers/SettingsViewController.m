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
#import "LogViewController.h"
#import "NumberField.h"
#import "PurgeViewController.h"
#import "SettingsViewController.h"

@implementation SettingsViewController

//@synthesize categoryViewController;

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
    kAppNameVersionRow = 0,
    kAuthorRow,
    kWebsiteRow,
    NUM_ABOUT_ROWS
};

- (id)initWithStyle:(UITableViewStyle)style
{
    if( self = [super initWithStyle:style] )
    {
	self.navigationItem.hidesBackButton = YES;
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
	self.title = @"Settings";
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

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
    [appDelegate flushDefaultInsulinTypes];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.75];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight
			   forView:self.navigationController.view
			     cache:YES];
    [self.navigationController popViewControllerAnimated:NO];	
    [UIView commitAnimations];
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
	    cell.textLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
	    // Work around the cell.textAlignment bug introduced in version 2.2 by
	    //  getting the first child UILabel and settting its textAlignment 
	    //  property directly
	    [[[[cell contentView] subviews] objectAtIndex:0] setTextAlignment:UITextAlignmentCenter];
	    if( row )
		cell.textLabel.textColor = [UIColor blueColor];	// Website and email links
	    switch( row )
	    {
		case kAppNameVersionRow:
		{
		    NSBundle *const mainBundle = [NSBundle mainBundle];
		    NSString *const v = [mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
		    NSString *const n = [mainBundle objectForInfoDictionaryKey:@"CFBundleName"];
		    cell.textLabel.text = [NSString stringWithFormat:@"%@ v%@", n, v];
		}
		break;
		case kAuthorRow: cell.textLabel.text = @"Brandon Fosdick <bfoz@bfoz.net>"; break;
		case kWebsiteRow: cell.textLabel.text = @"http://bfoz.net/projects/glucose"; break;
	    }
	    break;
    }

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if( kSectionAbout == section )
	return @"Copyright 2008-2010 Brandon Fosdick";
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
			exportViewController = [[ExportViewController alloc] initWithStyle:UITableViewStyleGrouped];
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
			    categoryViewController = [[CategoryViewController alloc] initWithStyle:UITableViewStyleGrouped];
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
			defaultInsulinTypeViewController.title = @"Default Insulin Types";
			defaultInsulinTypeViewController.multiCheck = YES;
		    }
		    [defaultInsulinTypeViewController setSelectedInsulinTypes:appDelegate.defaultInsulinTypes];
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
		    NSString* e = [@"mailto:bfoz@bfoz.net?subject=Glucose" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:e]];
		}
		break;
		case kWebsiteRow:
		    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://bfoz.net/projects/glucose/"]];
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
#pragma mark <InsulinTypeViewControllerDelegate>

- (void) insulinTypeViewControllerDidDeleteInsulinType:(InsulinType*)type;
{
    unsigned index = [appDelegate.insulinTypes indexOfObject:type];
    // Purge the record from the database and the Insulin Types array
    [appDelegate purgeInsulinTypeAtIndex:index];
}

- (BOOL) insulinTypeViewControllerDidSelectInsulinType:(InsulinType*)type
{
    if( [appDelegate.defaultInsulinTypes count] >= 2 )
	return NO;
    [appDelegate.defaultInsulinTypes addObject:type];
    return YES;
}

- (void) insulinTypeViewControllerDidUnselectInsulinType:(InsulinType*)type
{
    if( [appDelegate.defaultInsulinTypes containsObject:type] )
	[appDelegate.defaultInsulinTypes removeObjectIdenticalTo:type];
}

@end

