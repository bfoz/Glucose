#import "AppDelegate.h"
#import "Constants.h"

#import "CategoryViewController.h"
#import "ExportViewController.h"
#import "InsulinTypeViewController.h"
#import "LogModel.h"
#import "NumberField.h"
#import "PurgeViewController.h"
#import "SettingsViewController.h"

#define	URL_PROJECT_PAGE    @"http://bfoz.github.com/Glucose/"

@interface SettingsViewController () <CategoryViewControllerDelegate, InsulinTypeViewControllerDelegate, MFMailComposeViewControllerDelegate, NumberFieldDelegate>
@end

@implementation SettingsViewController
{
    UIToolbar*	    inputToolbar;
    UITextField*    currentEditingField;
}

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

- (id)init
{
    if( self = [super initWithStyle:UITableViewStyleGrouped] )
    {
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

- (void) doneAction:(id)sender
{
    // Persist changes to NSUserDefaults
    [model flushInsulinTypesForNewEntries];
    [[NSUserDefaults standardUserDefaults] synchronize];

    if( [self.delegate respondsToSelector:@selector(settingsViewControllerDidPressBack)] )
	[self.delegate settingsViewControllerDidPressBack];
}

- (void) glucoseUnitsAction:(UISegmentedControl*)sender
{
    switch( sender.selectedSegmentIndex )
    {
	case 0:
	    [LogModel setGlucoseUnitsSetting:kGlucoseUnits_mgdL];
	    highGlucoseWarningField.precision = 0;
	    lowGlucoseWarningField.precision = 0;
	    break;
	case 1:
	    [LogModel setGlucoseUnitsSetting:kGlucoseUnits_mmolL];
	    highGlucoseWarningField.precision = 1;
	    lowGlucoseWarningField.precision = 1;
	    break;
    }
    highGlucoseWarningField.text = [model highGlucoseWarningThresholdString];
    lowGlucoseWarningField.text = [model lowGlucoseWarningThresholdString];
    
    // Inform the delegate of the change of units
    if( [self.delegate respondsToSelector:@selector(settingsViewControllerDidChangeGlucoseUnits)] )
	[self.delegate settingsViewControllerDidChangeGlucoseUnits];
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
}

#pragma mark Accessor

- (UIToolbar*) inputToolbar
{
    if( !inputToolbar )
    {
	inputToolbar = [[UIToolbar alloc] init];
	UIBarButtonItem* cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(didTapCancelButton)];
	UIBarButtonItem* flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	UIBarButtonItem* barButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didTapDoneButton)];
	[inputToolbar setItems:[NSArray arrayWithObjects:cancelButton, flexibleSpace, barButton, nil] animated:NO];
	[inputToolbar sizeToFit];
    }
    return inputToolbar;
}

#pragma mark Actions

- (void) didTapCancelButton
{
    UITextField* tmp = currentEditingField;
    currentEditingField = nil;
    [tmp resignFirstResponder];
}

- (void) didTapDoneButton
{
    [currentEditingField resignFirstResponder];
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
	cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
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
	    if( row )
	    {
		f = [[NumberField alloc] initWithDelegate:self];
		f.frame = CGRectMake(0, kCellTopOffset*2, 50, 20);
		f.precision = (kGlucoseUnits_mgdL == model.glucoseUnitsSetting) ? 0 : 1;
		f.textAlignment = UITextAlignmentRight;
		cell.accessoryView = f;
	    }
	    switch( row )
	    {
		case kHighGlucoseWarningRow:
		    cell.textLabel.text = @"High Glucose Warning";
		    f.inputAccessoryView = self.inputToolbar;
		    f.text = [model highGlucoseWarningThresholdString];
		    f.textColor = [UIColor blueColor];
		    highGlucoseWarningField = f;
		    break;
		case kLowGlucoseWarningRow:
		    cell.textLabel.text = @"Low Glucose Warning";
		    f.inputAccessoryView = self.inputToolbar;
		    f.text = [model lowGlucoseWarningThresholdString];
		    f.textColor = [UIColor redColor];
		    lowGlucoseWarningField = f;
		    break;
		case kGlucoseUnitsRow:
		    cell.textLabel.text = @"Glucose Units";
		    UISegmentedControl* s = [[UISegmentedControl alloc] initWithItems:@[GlucoseUnitsTypeString_mgdL,GlucoseUnitsTypeString_mmolL]];
		    s.segmentedControlStyle = UISegmentedControlStyleBar;
		    [s addTarget:self action:@selector(glucoseUnitsAction:) forControlEvents:UIControlEventValueChanged];
		    s.selectedSegmentIndex = (kGlucoseUnits_mgdL == model.glucoseUnitsSetting) ? 0 : 1;
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
		    [self.navigationController pushViewController:[[ExportViewController alloc] initWithDataSource:self.model]
							 animated:YES];
		    break;
		case kPurgeRow:
		    [self.navigationController pushViewController:[[PurgeViewController alloc] initWithDataSource:model]
							 animated:YES];
		    break;
	    }
	    break;
	case kSectionCategoriesTypes:
	    switch( row )
	    {
		case kCategoryRow:
		{
		    CategoryViewController* categoryViewController = [[CategoryViewController alloc] init];
		    categoryViewController.delegate = self;
		    categoryViewController.model = model;

		    [self.navigationController pushViewController:categoryViewController animated:YES];
		    // Set editing mode after pushing the view controller. The UITableView doesn't exist
		    //  until loadView has been called. Until then, there's nothing to set editing mode on.
		    [categoryViewController setEditing:YES animated:NO];

		    break;
		}
		case kInsulinTypeRow:
		{
		    InsulinTypeViewController* insulinTypeViewController = [[InsulinTypeViewController alloc] init];
		    insulinTypeViewController.delegate = self;
		    insulinTypeViewController.model = model;
		    [insulinTypeViewController setMultiCheck:NO];

		    [self.navigationController pushViewController:insulinTypeViewController animated:YES];
		    // Set editing mode after pushing the view controller. The UITableView doesn't exist
		    //  until loadView has been called. Until then, there's nothing to set editing mode on.
		    [insulinTypeViewController setEditing:YES animated:NO];
		    break;
		}
		case kDefaultInsulinRow:
		{
		    InsulinTypeViewController* defaultInsulinTypeViewController = [[InsulinTypeViewController alloc] initWithStyle:UITableViewStyleGrouped];
		    defaultInsulinTypeViewController.delegate = self;
		    defaultInsulinTypeViewController.model = model;
		    defaultInsulinTypeViewController.title = @"Default Insulin Types";
		    defaultInsulinTypeViewController.multiCheck = YES;
		    [defaultInsulinTypeViewController setSelectedInsulinTypesWithArray:model.insulinTypesForNewEntries];

		    [self.navigationController pushViewController:defaultInsulinTypeViewController animated:YES];
		    break;
		}
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

#pragma mark UITextFieldDelegate

- (void) textFieldDidBeginEditing:(UITextField*)field
{
    currentEditingField = field;
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void) textFieldDidEndEditing:(UITextField *)textField
{
    if( currentEditingField )
    {
	NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
	formatter.numberStyle = NSNumberFormatterDecimalStyle;
	NSNumber* threshold = [formatter numberFromString:textField.text];

	if( threshold )
	{
	    if( textField == highGlucoseWarningField )
		[model setHighGlucoseWarningThreshold:threshold];
	    else if( textField == lowGlucoseWarningField )
		[model setLowGlucoseWarningThreshold:threshold];
	}
    }

    if( textField == highGlucoseWarningField )
	textField.text = [model highGlucoseWarningThresholdString];
    else if( textField == lowGlucoseWarningField )
	textField.text = [model lowGlucoseWarningThresholdString];

    currentEditingField = nil;
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

#pragma mark -
#pragma mark <CategoryViewControllerDelegate>

- (void) categoryViewControllerCreateCategory
{
    [model addCategoryWithName:nil];
    [model save];
}

- (void) categoryViewControllerDidDeleteCategory:(ManagedCategory*)category
{
    [model removeCategory:category];
    [model save];
}

- (void) categoryViewControllerDidSelectRestoreDefaults
{
    [model restoreBundledCategories];
    [model save];
}

#pragma mark -
#pragma mark <InsulinTypeViewControllerDelegate>

- (void) insulinTypeViewControllerCreateInsulinType
{
    [model addInsulinTypeWithName:nil];
}

- (void) insulinTypeViewControllerDidDeleteInsulinType:(ManagedInsulinType*)type;
{
    [model removeInsulinType:type];
}

- (void) insulinTypeViewControllerDidEndMultiSelect
{
    [model flushInsulinTypesForNewEntries];
}

- (BOOL) insulinTypeViewControllerDidSelectInsulinType:(ManagedInsulinType*)type
{
    if( [model.insulinTypesForNewEntries count] >= 2 )
	return NO;
    [model addInsulinTypeForNewEntries:type];
    return YES;
}

- (void) insulinTypeViewControllerDidSelectRestoreDefaults
{
    [model restoreBundledInsulinTypes];
}

- (void) insulinTypeViewControllerDidUnselectInsulinType:(ManagedInsulinType*)type
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

