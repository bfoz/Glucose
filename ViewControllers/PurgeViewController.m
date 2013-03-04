#import "AppDelegate.h"
#import "Constants.h"
#import "LogModel.h"

#import "PurgeViewController.h"

#define	kPurgeButtonSection	1

enum Sections
{
    kSectionRange = 0,
    kSectionPurgeButton,
    NUM_SECTIONS
};

@interface PurgeViewController () <UITextFieldDelegate>
@end

@implementation PurgeViewController
{
    NSDateFormatter*	dateFormatter;
    UIDatePicker*	datePicker;
    LogModel*	logModel;
    unsigned	numberOfRecordsToPurge;

    UITextField*    pickerField;
    UIToolbar*	    pickerInputAccessoryView;
    UILabel*	    pickerLabel;

    NSDate* endDate;
    NSDate* startDate;

    UITextField*    endField;
    UITextField*    startField;
}

- (id)initWithDataSource:(LogModel*)model
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
	self.title = @"Purge Records";
	logModel = model;

	dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[dateFormatter setDoesRelativeDateFormatting:YES];

	// !! Don't default to the first LogEntry here to avoid accidentally deleting the entire table
	NSUserDefaults *const defaults = [NSUserDefaults standardUserDefaults];
	NSDate* savedStart = [defaults objectForKey:kLastPurgeToDate];
	startDate = savedStart ? [savedStart dateByAddingTimeInterval:24*60*60] : [NSDate date];
	endDate = [NSDate date];

	numberOfRecordsToPurge = [logModel numberOfLogEntriesFromDate:startDate toDate:endDate];
    }
    return self;
}

- (UIView*) pickerInputAccessoryView
{
    if( !pickerInputAccessoryView )
    {
	pickerInputAccessoryView = [[UIToolbar alloc] init];
	UIBarButtonItem* cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(didTapCancelButton)];
	UIBarButtonItem* flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	UIBarButtonItem* barButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didTapDoneButton)];
	[pickerInputAccessoryView setItems:[NSArray arrayWithObjects:cancelButton, flexibleSpace, barButton, nil] animated:NO];
	[pickerInputAccessoryView sizeToFit];
    }

    return pickerInputAccessoryView;
}

- (UIDatePicker*) pickerInputView
{
    if( !datePicker )
    {
	datePicker = [[UIDatePicker alloc] init];
	datePicker.datePickerMode = UIDatePickerModeDate;
	[datePicker addTarget:self action:@selector(datePickerDidChangeValue:) forControlEvents:UIControlEventValueChanged];
    }
    return datePicker;
}

- (UITextField*) createPickerTextFieldWithFrame:(CGRect)frame
{
    UITextField* field = [[UITextField alloc] initWithFrame:frame];
    field.delegate = self;
    field.hidden = YES;
    field.inputAccessoryView = [self pickerInputAccessoryView];
    field.inputView = [self pickerInputView];

    return field;
}

- (NSString*) textForPurgeButton
{
    if( numberOfRecordsToPurge )
	return [NSString stringWithFormat:@"Purge %u record%@", numberOfRecordsToPurge, (numberOfRecordsToPurge > 1) ? @"s" : @""];
    return @"No records to purge";
}

- (void) updateThePurgeButton
{
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kSectionPurgeButton]
		  withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return NUM_SECTIONS;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch( section )
    {
	case kSectionRange:	    return 2;
	case kSectionPurgeButton:   return 1;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if( kSectionRange == section )
	return @"Records for the selected start and end days, as well as everything in between, will be purged.";
    else if( kSectionPurgeButton == section )
    {
	NSUserDefaults *const defaults = [NSUserDefaults standardUserDefaults];
	NSDate *const lastPurgeStart = [defaults objectForKey:kLastPurgeFromDate];
	NSDate *const lastPurgeEnd = [defaults objectForKey:kLastPurgeToDate];
	NSDate *const lastPurgedOn = [defaults objectForKey:kLastPurgedOnDate];

	if( lastPurgeStart && lastPurgeEnd && lastPurgedOn )
	{
	    if( lastPurgeStart && lastPurgeEnd && lastPurgedOn )
		return [NSString stringWithFormat:@"Last purged from %@ to %@ on %@",
			[dateFormatter stringFromDate:lastPurgeStart],
			[dateFormatter stringFromDate:lastPurgeEnd],
			[dateFormatter stringFromDate:lastPurgedOn]];
	}
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)section
{
    if( kSectionRange )
	return @"Select a date range to purge";
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";
    const unsigned section = indexPath.section;

    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:cellIdentifier];
    if( !cell )
    {
	UITableViewCellStyle style = (kSectionRange == section) ? UITableViewCellStyleValue1 : UITableViewCellStyleDefault;
	cell = [[UITableViewCell alloc] initWithStyle:style reuseIdentifier:cellIdentifier];
    }

    switch( section )
    {
	case kSectionRange:
	    switch( indexPath.row )
	    {
		case 0:
		    cell.textLabel.text = @"Start Date";
		    cell.detailTextLabel.text = [dateFormatter stringFromDate:startDate];
		    startField = [self createPickerTextFieldWithFrame:cell.detailTextLabel.frame];
		    [cell addSubview:startField];
		    break;
		case 1:
		    cell.textLabel.text = @"End Date";
		    cell.detailTextLabel.text = [dateFormatter stringFromDate:endDate];
		    endField = [self createPickerTextFieldWithFrame:cell.detailTextLabel.frame];
		    break;
	    }
	    break;
	case kSectionPurgeButton:
	    cell.textLabel.text = [self textForPurgeButton];
	    cell.textLabel.textAlignment = UITextAlignmentCenter;
	    cell.textLabel.textColor = numberOfRecordsToPurge ? [UIColor darkTextColor] : [UIColor grayColor];
	    break;
    }
    return cell;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    const unsigned section = indexPath.section;
    if( kSectionRange == section )
    {
	if( indexPath.row )
	    [endField becomeFirstResponder];
	else
	    [startField becomeFirstResponder];
    }
    else if( (kSectionPurgeButton == section) && numberOfRecordsToPurge )
    {
	[[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Purge %u Records?", numberOfRecordsToPurge]
				    message:[NSString stringWithFormat:@"Delete all records from %@ to %@?", [dateFormatter stringFromDate:startDate], [dateFormatter stringFromDate:endDate]]
				   delegate:self
			  cancelButtonTitle:@"Cancel"
			  otherButtonTitles:@"OK",nil] show];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark UIAlertViewDelegate

- (void) alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if( 0 == buttonIndex )	// Nothing to do if Cancel was clicked
	return;

    [logModel deleteLogEntriesFrom:startDate to:endDate];
    [logModel commitChanges];

    NSUserDefaults *const defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:startDate forKey:kLastPurgeFromDate];
    [defaults setObject:endDate forKey:kLastPurgeToDate];
    [defaults setObject:[NSDate date] forKey:kLastPurgedOnDate];

    [[[UIAlertView alloc] initWithTitle:@"Purge Complete"
				message:nil
			       delegate:nil
		      cancelButtonTitle:@"Ok"
		      otherButtonTitles:nil] show];
    [self.tableView reloadData];
}

#pragma mark Actions

- (void) datePickerDidChangeValue:(UIDatePicker*)sender
{
    pickerLabel.text = [dateFormatter stringFromDate:sender.date];
}

- (void) didTapCancelButton
{
    UITextField* temp = pickerField;
    pickerField = nil;
    [temp resignFirstResponder];
}

- (void) didTapDoneButton
{
    [pickerField resignFirstResponder];
}

#pragma mark UITextFieldDelegate

- (void) textFieldDidBeginEditing:(UITextField *)textField
{
    pickerField = textField;
    if( textField == endField )
    {
	pickerLabel = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:kSectionRange]].detailTextLabel;
	self.pickerInputView.date = endDate;
    }
    else if( textField == startField )
    {
	pickerLabel = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kSectionRange]].detailTextLabel;
	self.pickerInputView.date = startDate;
    }
}

- (void) textFieldDidEndEditing:(UITextField *)textField
{
    if( pickerField )
    {
	if( textField == endField )
	    endDate = self.pickerInputView.date;
	else if( textField == startField )
	    startDate = self.pickerInputView.date;
	pickerField = nil;
    }

    if( textField == endField )
	pickerLabel.text = [dateFormatter stringFromDate:endDate];
    else if( textField == startField )
	pickerLabel.text = [dateFormatter stringFromDate:startDate];

    numberOfRecordsToPurge = [logModel numberOfLogEntriesFromDate:startDate toDate:endDate];

    [self updateThePurgeButton];
}

@end

