#import "SlidingViewController.h"
#import "TextFieldCell.h"	// Needed for TextFieldCellDelegate

@class	Category;
@class	LogModel;
@protocol CategoryViewControllerDelegate;

@interface CategoryViewController : SlidingViewController <TextFieldCellDelegate, UIAlertViewDelegate>
{
    id <CategoryViewControllerDelegate>	__unsafe_unretained delegate;
    LogModel*			model;

    BOOL	didUndo;
	BOOL			dirty;
    Category*	deleteCategory;
    unsigned	deleteRow;
    Category*	__unsafe_unretained selectedCategory;
}

@property (nonatomic, unsafe_unretained) id <CategoryViewControllerDelegate>   delegate;
@property (nonatomic, strong) LogModel*				    model;
@property (nonatomic, unsafe_unretained) id selectedCategory;

@end

@protocol CategoryViewControllerDelegate <NSObject>

@optional
- (void) categoryViewControllerCreateCategory;
- (void) categoryViewControllerDidDeleteCategory:(Category*)category;
- (void) categoryViewControllerDidSelectCategory:(Category*)category;
- (void) categoryViewControllerDidSelectRestoreDefaults;

@end
