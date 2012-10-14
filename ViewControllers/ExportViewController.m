#import "AppDelegate.h"

#import <DropboxSDK/DropboxSDK.h>

#import "Constants.h"
#import "ExportViewController.h"

enum Sections
{
    kSectionDropBox = 0,
    kSectionDateRange,
    kSectionShare,
    kSectionExport,
    NUM_SECTIONS
};

@implementation ExportViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    if( self = [super initWithStyle:style] )
    {
	self.title = @"Export";
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dropboxSessionLinkedAccount:) name:kDropboxSessionLinkedAccountNotification object:nil];

    self.tableView.scrollEnabled = NO;	// Disable scrolling
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return NUM_SECTIONS;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch( section )
    {
	case kSectionDropBox:
	{
	    DBSession *const session = [DBSession sharedSession];
	    return [session isLinked] ? session.userIds.count+1 : 1;
	}
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{	
    NSString* cellID = @"cellID";
    const unsigned row	    = indexPath.row;
    const unsigned section  = indexPath.section;

    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:cellID];
    if( !cell )
    {
	cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    switch( section )
    {
	case kSectionDropBox:
	{
	    DBSession* session = [DBSession sharedSession];
	    if( session.isLinked )
	    {
		if( session.userIds.count == row )
		{
		    cell.textLabel.text = @"Link another Dropbox account";
		    cell.textLabel.textAlignment = UITextAlignmentCenter;
		    cell.textLabel.textColor = [UIColor blueColor];
		    cell.textLabel.font = [UIFont italicSystemFontOfSize:[UIFont systemFontSize]];
		}
		else
		{
		    cell.textLabel.text = [NSString stringWithFormat:@"Export to account %@", [session.userIds objectAtIndex:row]];
		    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
	    }
	    else
	    {
		cell.textLabel.text = @"Link your Dropbox account";
		cell.textLabel.textAlignment = UITextAlignmentCenter;
	    }
	    break;
	}
    }
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if( kSectionDropBox == section )
	return @"Linking a Dropbox account allows you to export your data to a folder in your Dropbox";
    return nil;
}

- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)section
{
    switch( section )
    {
        case 0: return @"Dropbox";
    }
    return nil;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    const unsigned section = indexPath.section;
    if( section == kSectionDropBox )
    {
	DBSession* session = [DBSession sharedSession];
	if( session.isLinked )
	{
	    // FIXME: Push a DropboxExportViewController
	}
	else if( session.userIds.count == indexPath.row )
	{
	    [[DBSession sharedSession] linkFromController:self];
	}
    }
}

#pragma mark Notification Handlers

- (void) dropboxSessionLinkedAccount:(NSNotification*)notification
{
    [self.tableView reloadData];
}

@end

