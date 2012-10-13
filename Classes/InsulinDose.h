#import <UIKit/UIKit.h>

@class InsulinType;

@interface InsulinDose : NSObject
{
	NSNumber*	dose;
}

@property (nonatomic, retain)	NSNumber*	dose;
@property (nonatomic, retain)	InsulinType*	insulinType;

+ (InsulinDose*)withType:(InsulinType*)t;

@end
