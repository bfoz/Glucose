#import "DropboxExportViewController.h"

#import <DropboxSDK/DropboxSDK.h>

#import "AppDelegate.h"
#import "Constants.h"
#import "LogEntry.h"
#import "LogModel.h"

enum Sections
{
    kSectionRange = 0,
    kSectionExport,
    kSectionUnlink,
    NUM_SECTIONS
};

@interface UIResponder (Glucose)
@property (readwrite, retain) UIView *inputView;
@property (readwrite, retain) UIView *inputAccessoryView;
@end

@interface DropboxExportViewController () <DBRestClientDelegate, UITextFieldDelegate>
@property (nonatomic, strong) DBRestClient* dropboxClient;
@end

@implementation DropboxExportViewController
{
    NSDateFormatter*	dateFormatter;
    UIDatePicker*	datePicker;
    NSString*	dropboxUserID;
    LogModel*	logModel;
    unsigned	numberOfRecordsToExport;
    NSString*	tempPath;

    UITextField*    pickerField;
    UIToolbar*	    pickerInputAccessoryView;
    UILabel*	    pickerLabel;
    UIAlertView*    progressAlertView;
    UIProgressView* progressView;

    NSDate*	startDate;
    NSDate*	endDate;

    UITextField*    endField;
    UITextField*    startField;
}

- (id) initWithUserID:(NSString*)userID dataSource:(LogModel*)model
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if( self )
    {
	self.title = @"Dropbox";
	dropboxUserID = userID;
	logModel = model;

	dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[dateFormatter setDoesRelativeDateFormatting:YES];

	startDate = [NSDate dateWithTimeIntervalSince1970:0];
	endDate = [NSDate date];

	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSDate* savedStart = [defaults objectForKey:kLastExportDropboxEndDate];
	if( savedStart )
	    startDate = [savedStart dateByAddingTimeInterval:24*60*60];
	else
	{
	    savedStart = [logModel dateOfEarliestLogEntry];
	    if( savedStart )
		startDate = savedStart;
	}

	numberOfRecordsToExport = [model numberOfLogEntriesFromDate:startDate toDate:endDate];
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

- (NSString*) textForExportButton
{
    if( numberOfRecordsToExport )
	return [NSString stringWithFormat:@"Export %u record%@", numberOfRecordsToExport, (numberOfRecordsToExport > 1) ? @"s" : @""];
    return @"No records to export";
}

- (void) updateTheExportButton
{
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kSectionExport]
		  withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return NUM_SECTIONS;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch( section )
    {
	case kSectionRange: return 2;
	case kSectionExport: return numberOfRecordsToExport ? 1 : 0;
	case kSectionUnlink: return 1;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    const unsigned row = indexPath.row;
    const unsigned section = indexPath.section;

    if( !cell )
    {
	UITableViewCellStyle style = (kSectionRange == section) ? UITableViewCellStyleValue1 : UITableViewCellStyleDefault;
	cell = [[UITableViewCell alloc] initWithStyle:style reuseIdentifier:cellIdentifier];
    }

    switch( section )
    {
	case kSectionRange:
	    if( 0 == row )
	    {
		cell.textLabel.text = @"Start Date";
		cell.detailTextLabel.text = [dateFormatter stringFromDate:startDate];
		startField = [self createPickerTextFieldWithFrame:cell.detailTextLabel.frame];
		[cell addSubview:startField];
	    }
	    else if( 1 == row )
	    {
		cell.textLabel.text = @"End Date";
		cell.detailTextLabel.text = [dateFormatter stringFromDate:endDate];
		endField = [self createPickerTextFieldWithFrame:cell.detailTextLabel.frame];
		[cell addSubview:endField];
	    }
	    break;
	case kSectionExport:
	    cell.textLabel.text = [self textForExportButton];
	    cell.textLabel.textAlignment = NSTextAlignmentCenter;
	    cell.textLabel.textColor = numberOfRecordsToExport ? [UIColor darkTextColor] : [UIColor grayColor];
	    break;

	case kSectionUnlink:
	    cell.backgroundColor = [UIColor redColor];
	    cell.textLabel.text = @"Unlink this account";
	    cell.textLabel.textAlignment = NSTextAlignmentCenter;
	    cell.textLabel.textColor = [UIColor whiteColor];
	    break;
    }

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if( kSectionRange == section )
	return @"The exported data will include records for the selected start and end days, as well as everything in between.";
    else if( kSectionExport == section )
    {
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSDate* lastEndDate = [defaults objectForKey:kLastExportDropboxEndDate];
	NSDate* lastStartDate = [defaults objectForKey:kLastExportDropboxStartDate];
	NSDate* lastExportDate = [defaults objectForKey:kLastExportDropboxDate];
	if( lastEndDate && lastStartDate && lastExportDate )
	{
	    NSString* date = [dateFormatter stringFromDate:lastExportDate];
	    if( ![date isEqualToString:@"Today"] )
		date = [NSString stringWithFormat:@"on %@", date];
	    return [NSString stringWithFormat:@"Your last Dropbox export was %@ and included records from %@ to %@",
		    date,
		    [dateFormatter stringFromDate:lastStartDate],
		    [dateFormatter stringFromDate:lastEndDate]];
	}
    }
    else if( kSectionUnlink == section )
	return @"Unlinking your account will delete the account credentials stored on this device, and disable exporting to this Dropbox account, but won't delete any previously exported files.";
    return nil;
}

- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)section
{
    if( kSectionRange == section )
	return @"Select a date range to export";
    return nil;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    const unsigned section = indexPath.section;
    if( (kSectionExport == section) && numberOfRecordsToExport )
    {
	NSData* data = [logModel csvDataFromDate:startDate toDate:endDate];
	NSString* filename = [NSString stringWithFormat:@"Export from %@ to %@.csv", [logModel shortStringFromDate:startDate], [logModel shortStringFromDate:endDate]];
	filename = [filename stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
	tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];

	if( [data writeToFile:tempPath atomically:YES] )
	{
	    [self.dropboxClient uploadFile:filename
				    toPath:@"/"
			     withParentRev:nil
				  fromPath:tempPath];

	    // Create an alert for displaying a progress bar while uploading
	    progressAlertView = [[UIAlertView alloc] initWithTitle:@"Exporting..."
							   message:nil
						      delegate:nil
						 cancelButtonTitle:nil
						 otherButtonTitles:nil];
	    // Add a progress bar to the alert
	    progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(30,80,225,90)];
	    [progressAlertView addSubview:progressView];
	    [progressView setProgressViewStyle:UIProgressViewStyleDefault];
	    [progressAlertView show];
	}
	else
	{
	    [[[UIAlertView alloc] initWithTitle:@"Oops"
					message:@"Could not create a temporary file"
				       delegate:nil
			      cancelButtonTitle:@"Ok"
			      otherButtonTitles:nil] show];
	}
    }
    else if( kSectionRange == section )
    {
	if( indexPath.row )
	    [endField becomeFirstResponder];
	else
	    [startField becomeFirstResponder];
    }
    else if( kSectionUnlink == section )
    {
	DBSession* session = [DBSession sharedSession];
	[session unlinkUserId:dropboxUserID];
	[[NSNotificationCenter defaultCenter] postNotificationName:kDropboxSessionUnlinkedAccountNotification object:session];
	[self.navigationController popViewControllerAnimated:YES];

	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	[defaults removeObjectForKey:kLastExportDropboxDate];
	[defaults removeObjectForKey:kLastExportDropboxEndDate];
	[defaults removeObjectForKey:kLastExportDropboxStartDate];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark Accessors

- (DBRestClient *) dropboxClient
{
    if( !_dropboxClient)
    {
	_dropboxClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
	_dropboxClient.delegate = self;
    }
    return _dropboxClient;
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

#pragma mark - Delegates

#pragma mark DBRestClientDelegate

- (void) cleanupAfterTheUpload
{
    [progressAlertView dismissWithClickedButtonIndex:0 animated:YES];
    progressAlertView = nil;
    if( tempPath )
	[[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
}

- (void) restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath metadata:(DBMetadata*)metadata
{
    [self cleanupAfterTheUpload];

    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSDate date] forKey:kLastExportDropboxDate];
    [defaults setObject:endDate forKey:kLastExportDropboxEndDate];
    [defaults setObject:startDate forKey:kLastExportDropboxStartDate];

    [self updateTheExportButton];
}

- (void) restClient:(DBRestClient*)client uploadProgress:(CGFloat)progress forFile:(NSString*)destPath from:(NSString*)srcPath
{
    [progressView setProgress:progress];
}

- (void) restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error
{
    [self cleanupAfterTheUpload];

    [[[UIAlertView alloc] initWithTitle:@"Failed to upload"
			       message:error.localizedDescription
			      delegate:self
		      cancelButtonTitle:@"Ok"
		     otherButtonTitles:nil] show];
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

    numberOfRecordsToExport = [logModel numberOfLogEntriesFromDate:startDate toDate:endDate];

    [self updateTheExportButton];
}

@end
