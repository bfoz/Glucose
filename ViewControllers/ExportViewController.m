#import "AppDelegate.h"

#import <DropboxSDK/DropboxSDK.h>

#import "Constants.h"
#import "ExportViewController.h"
#import "DropboxExportViewController.h"

enum Sections
{
    kSectionDropBox = 0,
    NUM_SECTIONS
};

@interface ExportViewController () <DBRestClientDelegate>
@property (nonatomic, strong) DBRestClient* dropboxClient;
@end

@implementation ExportViewController
{
    NSMutableDictionary*    accountInfo;
    LogModel*	logModel;
}

- (id)initWithDataSource:(LogModel*)model
{
    if( self = [super initWithStyle:UITableViewStyleGrouped] )
    {
	accountInfo = [[NSMutableDictionary alloc] init];
	logModel = model;
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Export";

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dropboxSessionLinkedAccount:) name:kDropboxSessionLinkedAccountNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dropboxSessionUnlinkedAccount:) name:kDropboxSessionUnlinkedAccountNotification object:nil];

    DBSession *const session = [DBSession sharedSession];
    if( [session isLinked] )
	[self.dropboxClient loadAccountInfo];

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
		    NSString* userID = [session.userIds objectAtIndex:row];
		    DBAccountInfo* account = [accountInfo objectForKey:userID];
		    NSString* accountName = account.displayName;
		    if( accountName && accountName.length )
			cell.textLabel.text = [NSString stringWithFormat:@"Export to %@", accountName];
		    else
			cell.textLabel.text = [NSString stringWithFormat:@"Export to account %@", userID];
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
	    DropboxExportViewController* controller = [[DropboxExportViewController alloc] initWithUserID:[session.userIds objectAtIndex:indexPath.row] dataSource:logModel];
	    [self.navigationController pushViewController:controller animated:YES];
	}
	else if( session.userIds.count == indexPath.row )
	{
	    [[DBSession sharedSession] linkFromController:self];
	}
    }
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

#pragma mark DBRestClientDelegate

- (void)restClient:(DBRestClient*)client loadedAccountInfo:(DBAccountInfo*)info
{
    [accountInfo setObject:info forKey:info.userId];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kSectionDropBox]
		  withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark Notification Handlers

- (void) dropboxSessionLinkedAccount:(NSNotification*)notification
{
    [self.dropboxClient loadAccountInfo];

    [self.tableView reloadData];
}

- (void) dropboxSessionUnlinkedAccount:(NSNotification*)notification
{
    [self.tableView reloadData];
}

@end

