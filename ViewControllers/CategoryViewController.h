#import "TextFieldCell.h"	// Needed for TextFieldCellDelegate

@class	ManagedCategory;
@class	LogModel;
@protocol CategoryViewControllerDelegate;

@interface CategoryViewController : UITableViewController <TextFieldCellDelegate, UIAlertViewDelegate>

@property (nonatomic, weak) id <CategoryViewControllerDelegate>   delegate;
@property (nonatomic, strong) LogModel*				    model;
@property (nonatomic, strong) ManagedCategory* selectedCategory;

- (id) initWithStyle:(UITableViewStyle)style logModel:(LogModel*)logModel;

@end

@protocol CategoryViewControllerDelegate <NSObject>

@optional
- (void) categoryViewControllerDidSelectCategory:(ManagedCategory*)category;
- (void) categoryViewControllerDidSelectRestoreDefaults;

@end
