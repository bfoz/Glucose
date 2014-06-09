#import "AppDelegate.h"

#import <Dropbox/Dropbox.h>

#import "Constants.h"
#import "ExportViewController.h"
#import "DropboxExportViewController.h"

enum Sections
{
    kSectionDropBox = 0,
    NUM_SECTIONS
};

@implementation ExportViewController
{
    LogModel*	logModel;
}

- (id)initWithDataSource:(LogModel*)model
{
    if( self = [super initWithStyle:UITableViewStyleGrouped] )
    {
	logModel = model;
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Export";

    DBAccountManager* manager = DBAccountManager.sharedManager;
    [manager addObserver:self block:^(DBAccount* account) {
	if( account.isLinked )
	{
	    if( account.info )
		[account removeObserver:self];
	    else
	    {
		__weak DBAccount* weakAccount = account;
		[account addObserver:self block:^{
		    if( weakAccount.isLinked && weakAccount.info )
		    {
			[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kSectionDropBox]
				      withRowAnimation:UITableViewRowAnimationFade];
			[weakAccount removeObserver:self];
		    }
		}];
	    }
	}

	[self.tableView reloadData];
    }];

    self.tableView.scrollEnabled = NO;	// Disable scrolling
}

- (void) dealloc
{
    [[DBAccountManager sharedManager] removeObserver:self];
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
	    NSArray* accounts = [DBAccountManager sharedManager].linkedAccounts;
	    return accounts ? accounts.count+1 : 1;
	}
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{	
    NSString* cellID = @"cellID";
    const NSInteger row	    = indexPath.row;
    const NSInteger section  = indexPath.section;

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
	    NSArray* accounts = [DBAccountManager sharedManager].linkedAccounts;
	    if( accounts )
	    {
		if( accounts.count == row )
		{
		    cell.textLabel.text = @"Link another Dropbox account";
		    cell.textLabel.textAlignment = NSTextAlignmentCenter;
		    cell.textLabel.textColor = [UIColor blueColor];
		    cell.textLabel.font = [UIFont italicSystemFontOfSize:[UIFont systemFontSize]];
		}
		else
		{
		    DBAccount* account = [accounts objectAtIndex:row];
		    NSString* accountName = account.info.displayName;
		    if( accountName && accountName.length )
			cell.textLabel.text = [NSString stringWithFormat:@"Export to %@", accountName];
		    else
			cell.textLabel.text = [NSString stringWithFormat:@"Export to account %@", account.userId];
		    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
	    }
	    else
	    {
		cell.textLabel.text = @"Link your Dropbox account";
		cell.textLabel.textAlignment = NSTextAlignmentCenter;
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
    const NSInteger section = indexPath.section;
    if( section == kSectionDropBox )
    {
	NSArray* accounts = [DBAccountManager sharedManager].linkedAccounts;
	if( accounts )
	{
	    DBAccount* account = accounts[indexPath.row];
	    DropboxExportViewController* controller = [[DropboxExportViewController alloc] initWithDropboxAccount:account dataSource:logModel];
	    [self.navigationController pushViewController:controller animated:YES];
	}
	else
	    [[DBAccountManager sharedManager] linkFromController:self];
    }
}

@end

