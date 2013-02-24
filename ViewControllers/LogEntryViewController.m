#import "AppDelegate.h"
#import "Category.h"
#import "CategoryViewController.h"
#import "Constants.h"
#import "DateField.h"
#import "DoseFieldCell.h"
#import "DualTableViewCell.h"
#import "FlurryLogger.h"
#import "InsulinTypeViewController.h"
#import "LabelCell.h"
#import "LogEntryViewController.h"
#import "LogDay.h"
#import "LogModel.h"
#import "ManagedCategory.h"
#import "ManagedLogDay+App.h"
#import "ManagedLogEntry+App.h"
#import "ManagedInsulinDose.h"
#import "ManagedInsulinType.h"
#import "NumberFieldCell.h"
#import "TextViewCell.h"

#define	kInsulinCellID			@"InsulinCellID"

enum Sections
{
    kSectionGlucose = 0,
    kSectionInsulin,
    kSectionNote,
    NUM_SECTIONS
};

enum GlucoseSectionRows
{
    kRowTimestamp = 0,
    kRowCategory,
    kRowGlucose,
};

@interface LogEntryViewController () <CategoryViewControllerDelegate, DateFieldDelegate, DoseFieldCellDelegate, InsulinTypeViewControllerDelegate, NumberFieldCellDelegate, TextViewCellDelegate>
{
    CategoryViewController*	categoryViewController;
    InsulinTypeViewController*	insulinTypeViewController;
}

@property (nonatomic, strong) NSDateFormatter*	dateFormatter;

@property (nonatomic, strong) UILabel*	    categoryLabel;
@property (nonatomic, strong) DateField*    timestampField;
@property (nonatomic, strong) UILabel*	    timestampLabel;

@end

@implementation LogEntryViewController
{
    NumberFieldCell*	glucoseCell;
    TextViewCell*	noteCell;
    UIToolbar*	    inputToolbar;
    UITextField*    currentEditingField;

    ManagedCategory*	selectedCategory;
    NSIndexPath*	selectedIndexPath;
}

@synthesize dateFormatter;
@synthesize delegate;
@synthesize editingNewEntry;
@synthesize model;

static unsigned InsulinPrecision;
static NSUserDefaults* defaults = nil;

- (id) initWithStyle:(UITableViewStyle)style
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (id) initWithLogEntry:(ManagedLogEntry*)logEntry
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if( self )
    {
	editingNewEntry = !logEntry;
	
	self.logEntry = logEntry;
	selectedCategory = logEntry.category;

	// Create a date formatter to convert the date to a string format.
	dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	
	if( !defaults )
	    defaults = [NSUserDefaults standardUserDefaults];
	NSNumber* p = [defaults objectForKey:kDefaultInsulinPrecision];
	InsulinPrecision = p ? [p intValue] : 0;
    }
    return self;
}

- (id) initWithLogModel:(LogModel*)logModel
{
    self = [self initWithLogEntry:nil];
    if( self )
    {
	self.model = logModel;
	[self setEditing:YES animated:NO];
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.tableView.allowsSelectionDuringEditing = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self updateTitle];		    // Update the navigation item title
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if( ![self isMovingToParentViewController] )
	if( editingNewEntry )
	    [glucoseCell becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if( [self isMovingFromParentViewController] && self.editing )
	[self cancelEditingLogEntry];
}

- (void)setEditing:(BOOL)e animated:(BOOL)animated
{
    BOOL previousEditing = self.editing;

    [super setEditing:e animated:animated];

    if( previousEditing && !e )
    {
	if( self.editingNewEntry )
	    [self finishEditingNewLogEntry];
	else
	    [self finishEditingLogEntry];
    }

    [self updateTitle];

    // Reload the table to update the view to reflect the new edit state
    [self.tableView reloadData];
}

#pragma mark -

- (void) cancelEditingLogEntry
{
    [self.delegate logEntryViewControllerDidCancelEditing];
}

- (void) finishEditingLogEntry
{
    self.logEntry.category = selectedCategory;
    self.logEntry.glucose = glucoseCell.number;
    self.logEntry.note = noteCell.text;
    self.logEntry.timestamp = self.timestampField.date;

    unsigned i = 0;
    DoseFieldCell* cell = nil;
    NSMutableArray* insulinDoses = [NSMutableArray array];
    while( (cell = (DoseFieldCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:i inSection:kSectionInsulin]]) )
    {
	if( cell.doseField.number && cell.insulinType )
	{
	    if( cell.dose )
	    {
		cell.dose.dose = cell.doseField.number;
		cell.dose.insulinType = cell.insulinType;
		[insulinDoses addObject:cell.dose];
	    }
	    else
		[insulinDoses addObject:[self.logEntry addInsulinDose:cell.doseField.number withInsulinType:cell.insulinType]];
	}
	++i;
    }
    self.logEntry.insulinDoses = [NSOrderedSet orderedSetWithArray:insulinDoses];

    ManagedLogDay *const newDay = [self.model logDayForDate:self.logEntry.timestamp];
    if( newDay != self.logEntry.logDay )
    {
	ManagedLogDay* oldDay = self.logEntry.logDay;

	NSMutableOrderedSet* entries = [NSMutableOrderedSet orderedSetWithOrderedSet:newDay.logEntries];
	[entries insertObject:self.logEntry atIndex:0];
	newDay.logEntries = entries;

	[newDay updateStatistics];
	[oldDay updateStatistics];
    }

    [self.model commitChanges];
}

- (void) finishEditingNewLogEntry
{
    self.logEntry = [model insertManagedLogEntry];
    [self finishEditingLogEntry];
    self.editingNewEntry = NO;
    [delegate logEntryView:self didEndEditingEntry:self.logEntry];
}

- (void) disableSaveButton
{
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void) enableSaveButton
{
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void) updateCategoryLabel
{
    if( selectedCategory )
    {
	self.categoryLabel.text = selectedCategory.name;
	self.categoryLabel.textColor = [UIColor darkTextColor];
    }
    else
    {
	self.categoryLabel.text = @"Category";
	self.categoryLabel.textColor = [UIColor lightGrayColor];
    }
}

- (void) updateTitle
{
    if( self.editingNewEntry )
	self.title = @"New Entry";
    else if( self.editing )
	self.title = @"Edit Entry";
    else
	self.title = @"Details";
}

#pragma mark Accessory Toolbar

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
    [currentEditingField.undoManager undo];
    [currentEditingField resignFirstResponder];
}

- (void) didTapDoneButton
{
    [currentEditingField resignFirstResponder];
}

#pragma mark -
#pragma mark <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv
{
    return NUM_SECTIONS;
}

// Section 0 - Timestamp/Category/Glucose
//	Row 0 => Row 0
//	Row 2 (Glucose) => Row 1 if not editing and there is a glucose reading, but no category
- (unsigned) translateRow:(unsigned)row inSection:(unsigned)section
{
    if( !self.editing && (0 == section) && (1==row) && !selectedCategory && self.logEntry.glucose )
	return 2;
    return row;
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section
{
    switch( section )
    {
	case kSectionGlucose:
	    if( self.editing )
		return 3;
	    else
		return 1 + (self.logEntry.glucose ? 1 : 0) + (selectedCategory ? 1 : 0);
	case kSectionInsulin:
	    return self.logEntry ? self.logEntry.insulinDoses.count : [model insulinTypesForNewEntries].count;
	case kSectionNote:
	    if( self.editing )
		return 1;
	    else
		return (self.logEntry.note && [self.logEntry.note length]) ? 1 : 0;
    }
    return 0;
}

- (NSString*) cellIDForSection:(unsigned)section row:(unsigned)row
{
    if( self.editing )
    {
	switch( section )
	{
	    case kSectionGlucose:
		switch( row )
		{
		    case kRowTimestamp: return @"Timestamp";
		    case kRowCategory:	return @"Category";
		}
		break;
	}
    }
    else
    {
	switch( section )
	{
	    case kSectionGlucose:
		if( kRowGlucose == row )
		    return @"Glucose";
		break;
	    case kSectionInsulin:   return kInsulinCellID;
	    case kSectionNote:	    return @"NoteID";
	}
    }
    return @"CellID";
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    const unsigned section = indexPath.section;
    unsigned row = [self translateRow:indexPath.row inSection:section];

    NSString *const cellID = [self cellIDForSection:section row:row];

    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:cellID];	// Get the appropriate cell

    if( !cell )
    {
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	if( kSectionGlucose == section && ((kRowTimestamp == row) || (kRowCategory == row)) )	// Standard UITableView cell for Timestamp and Category
	{
	    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
	    cell.accessoryType = self.editing ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
	    cell.textLabel.backgroundColor = [UIColor clearColor];
	    cell.textLabel.textAlignment = UITextAlignmentCenter;
	    if( kRowCategory == row )
		self.categoryLabel = cell.textLabel;
	}
	else if( !self.editing )
	{
	    switch( section )
	    {
		case kSectionGlucose:
		    if( kRowGlucose == row )
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
		    break;
		case kSectionInsulin:
		    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
						  reuseIdentifier:cellID];
		    // Use the same font size for both labels
		    cell.detailTextLabel.font = cell.textLabel.font;
		    cell.detailTextLabel.backgroundColor = [UIColor clearColor];
		    cell.textLabel.backgroundColor = [UIColor clearColor];
		    break;
		case kSectionNote:
		    cell = [[LabelCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
		    break;
	    }
	}
    }

    if( kSectionGlucose == section )
    {
	switch( row )
	{
	    case 0:	// Timestamp
	    {
		cell.textLabel.text = [dateFormatter stringFromDate:(self.logEntry ? self.logEntry.timestamp : [NSDate date])];
		cell.textLabel.textAlignment = UITextAlignmentCenter;
		_timestampField = [[DateField alloc] initWithFrame:cell.textLabel.frame];
		_timestampField.delegate = self;
		_timestampField.hidden = YES;
		[cell addSubview:_timestampField];
		self.timestampLabel = cell.textLabel;
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		break;
	    }
	    case 1:	// Category
		[self updateCategoryLabel];
		break;
	    case 2:	// Glucose
		if( self.editing )
		{
		    if( self.logEntry )
			glucoseCell = [NumberFieldCell cellForLogEntry:self.logEntry
							 accessoryView:self.inputToolbar
							      delegate:self
							     tableView:tv];
		    else
			glucoseCell = [NumberFieldCell cellForNumber:nil
							   precision:[model glucosePrecisionForNewEntries]
							 unitsString:[LogModel glucoseUnitsSettingString]
						  inputAccessoryView:self.inputToolbar
							    delegate:self
							   tableView:tv];
		    cell = glucoseCell;
		}
		else
		{
		    cell.textLabel.text = [self.logEntry glucoseString];
		    cell.textLabel.textAlignment = UITextAlignmentCenter;

		    // Color the glucose values accordingly
		    const float glucose = [self.logEntry.glucose floatValue];

		    if( glucose > [model highGlucoseWarningThreshold] )
			cell.textLabel.textColor = [UIColor blueColor];
		    else if( glucose < [model lowGlucoseWarningThreshold] )
			cell.textLabel.textColor = [UIColor redColor];
		    else
			cell.textLabel.textColor = [UIColor darkTextColor];

		}
		break;
	}
    }
    else if( kSectionInsulin == section )
    {
	// If the entry doesn't have a valid number for an insulin type use a regular cell and display the short name. 
	// Otherwise, use a dual column cell.
	ManagedInsulinDose* dose = [self.logEntry.insulinDoses objectAtIndex:row];

	if( self.editing )
	{
	    if( dose )
	    {
		cell = [DoseFieldCell cellForInsulinDose:dose
					   accessoryView:self.inputToolbar
						delegate:self
					       precision:InsulinPrecision
					       tableView:tv];
	    }
	    else
	    {
		cell = [DoseFieldCell cellForInsulinType:[[model insulinTypesForNewEntries] objectAtIndex:row]
					   accessoryView:self.inputToolbar
						delegate:self
					       precision:InsulinPrecision
					       tableView:tv];
	    }
	}
	else if( dose )
	{
	    if( dose.dose )
		cell.detailTextLabel.text = [dose.dose stringValue];
	    if( dose.insulinType )
		cell.textLabel.text = dose.insulinType.shortName;
	}
    }
    else if( kSectionNote == section )
    {
	if( self.editing )
	{
	    noteCell = [TextViewCell cellForLogEntry:self.logEntry
					    delegate:self
				  inputAccessoryView:self.inputToolbar
					   tableView:tv];
	    cell = noteCell;
	}
	else
	    cell.textLabel.text = self.logEntry.note;
    }

    return cell;
}

- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)path
{
    if( UITableViewCellEditingStyleDelete == editingStyle )
    {
	[self.logEntry removeObjectFromInsulinDosesAtIndex:path.row];
	[tv deleteRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationFade];
    }
    else if( UITableViewCellEditingStyleInsert == editingStyle )
    {
	// Fake a row selection to display the insulin picker
	[self tableView:tv didSelectRowAtIndexPath:path];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if( kSectionNote == section )
	if( self.editing || self.logEntry.note )
	    return @"Note";
    return nil;
}

#pragma mark -
#pragma mark <UITableViewDelegate>

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)path
{
    if( 1 == path.section )
	return YES;
    return NO;
}

- (NSIndexPath *)tableView:(UITableView *)tv willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Only allow selection if editing.
    return (self.editing) ? indexPath : nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)path
{
    const unsigned section = path.section;

    if( 0 == section )
    {
	switch( path.row )
	{
	    case 0: 
		[_timestampField becomeFirstResponder];
		[self.tableView deselectRowAtIndexPath:path animated:YES];
		break;
	    case 1: 
		if( !categoryViewController )
		{
		    categoryViewController = [[CategoryViewController alloc] initWithStyle:UITableViewStylePlain];
		    categoryViewController.delegate = self;
		    categoryViewController.model = model;
		}
		categoryViewController.selectedCategory = selectedCategory;
		[self presentModalViewController:categoryViewController animated:YES];
		break;
	    case 2: // Go into edit mode if the user taps anywhere on the row
		[glucoseCell becomeFirstResponder];
		break;
	}
    }
    else if( kSectionInsulin == section )
    {
	if( !insulinTypeViewController )
	{
	    insulinTypeViewController = [[InsulinTypeViewController alloc] initWithStyle:UITableViewStylePlain];
	    insulinTypeViewController.delegate = self;
	    insulinTypeViewController.model = model;
	}
	selectedIndexPath = path;
	DoseFieldCell* cell = (DoseFieldCell*)[self.tableView cellForRowAtIndexPath:path];
	[insulinTypeViewController setSelectedInsulinType:cell.insulinType];
	[self presentModalViewController:insulinTypeViewController animated:YES];
    }
    else if( 2 == section )
    {
    }
}

// The editing style for a row is the kind of button displayed to the left of the cell when in editing mode.
- (UITableViewCellEditingStyle)tableView:(UITableView *)tv editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // No editing style if not editing or the index path is nil.
    if( !self.editing || !indexPath )
	return UITableViewCellEditingStyleNone;

    // Only section 1 can be edited (insulin doses)
    if( indexPath.section != 1 )
	return UITableViewCellEditingStyleNone;

    if( indexPath.row >= self.logEntry.insulinDoses.count )
	return UITableViewCellEditingStyleInsert;
    else
	return UITableViewCellEditingStyleDelete;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath*)path
{
    if( kSectionNote == path.section )
    {
	const BOOL e = self.editing;
	// If editing and there's no text, return a standard size
	if( e && !noteCell.textView.text )
	    return 44*2;
	// Otherwise, resize for the text
	CGSize s = [self.logEntry.note sizeWithFont:[UIFont boldSystemFontOfSize:[UIFont labelFontSize]]
			  constrainedToSize:CGSizeMake(284, 2000) lineBreakMode:UILineBreakModeWordWrap];
	CGFloat h = s.height+2*kCellTopOffset;
	// If editing and the row started off with text, don't return smaller than two rows
	// Otherwise, never return smaller than one row
	return MAX(h, (e ? 44*2 : 44));
    }
    return 44;
}

#pragma mark NumberFieldCellDelegate

- (void)numberFieldCellDidBeginEditing:(NumberFieldCell*)cell
{
    [cell.field.undoManager registerUndoWithTarget:cell selector:@selector(setNumber:) object:cell.number];
    currentEditingField = cell.field;
    [self disableSaveButton];
}

- (void)numberFieldCellDidEndEditing:(NumberFieldCell*)cell
{
    currentEditingField = nil;
    [self enableSaveButton];
}

#pragma mark UITextFieldDelegate

- (void) dateFieldDidChangeValue:(DateField *)dateField
{
    _timestampLabel.text = [dateFormatter stringFromDate:dateField.date];
}

- (void) textFieldDidBeginEditing:(DateField*)dateField
{
    [[FlurryLogger currentFlurryLogger] logEventWithName:kFlurryEventNewLogEntryDidTapTimestamp];
    dateField.date = self.logEntry ? self.logEntry.timestamp : [NSDate date];
    [dateField.undoManager registerUndoWithTarget:dateField selector:@selector(setDate:) object:dateField.date];
    [self disableSaveButton];
}

- (void) textFieldDidEndEditing:(DateField *)dateField
{
    [[FlurryLogger currentFlurryLogger] logEventWithName:kFlurryEventNewLogEntryDidChangeTimestamp];
    _timestampLabel.text = [dateFormatter stringFromDate:dateField.date];
    [self enableSaveButton];
}

- (void) dateFieldWillCancelEditing:(DateField *)dateField
{
    [[FlurryLogger currentFlurryLogger] logEventWithName:kFlurryEventNewLogEntryDidCancelTimestamp];
    [dateField.undoManager undo];
    _timestampLabel.text = [dateFormatter stringFromDate:dateField.date];
}

#pragma mark CategoryViewControllerDelegate

- (void) categoryViewControllerDidSelectCategory:(ManagedCategory *)category
{
    [self dismissModalViewControllerAnimated:YES];
    selectedCategory = category;
    [self updateCategoryLabel];
}

#pragma mark DoseFieldCellDelegate

- (void)doseDidBeginEditing:(DoseFieldCell*)cell
{
    [cell.doseField.undoManager registerUndoWithTarget:cell.doseField selector:@selector(setNumber:) object:cell.doseField.number];
    currentEditingField = cell.doseField;
    [self disableSaveButton];
}

- (void)doseDidEndEditing:(DoseFieldCell *)cell
{
    cell.dose.dose = [cell.doseField number];
    if( editingNewEntry )
    {
	NSIndexPath* path = [self.tableView indexPathForCell:cell];
	NSIndexPath* next = [NSIndexPath indexPathForRow:path.row+1 inSection:kSectionInsulin];
	DoseFieldCell* cell = (DoseFieldCell*)[self.tableView cellForRowAtIndexPath:next];
	if( cell )	// Found a next insulin row
	{
	    [cell.doseField becomeFirstResponder];
	    return;
	}
    }

    cell.dose = cell.dose;

    currentEditingField = nil;
    [self enableSaveButton];
}

#pragma mark -
#pragma mark <InsulinTypeViewControllerDelegate>

- (BOOL) insulinTypeViewControllerDidSelectInsulinType:(ManagedInsulinType*)insulinType
{
    [self dismissModalViewControllerAnimated:YES];

    if( selectedIndexPath )
    {
	DoseFieldCell* cell = (DoseFieldCell*)[self.tableView cellForRowAtIndexPath:selectedIndexPath];
	cell.insulinType = insulinType;
	selectedIndexPath = nil;
    }

    return YES;
}

#pragma mark TextViewCellDelegate

- (void) textViewCellDidBeginEditing:(TextViewCell*)cell
{
    currentEditingField = (UITextField*)cell.textView;
    [self disableSaveButton];
}

- (void) textViewCellDidEndEditing:(TextViewCell*)cell
{
    currentEditingField = nil;
    [self enableSaveButton];
}

@end
