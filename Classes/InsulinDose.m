#import "InsulinDose.h"
#import "InsulinType.h"

@implementation InsulinDose

@synthesize dose, insulinType;

+ (InsulinDose*)withType:(InsulinType*)t
{
	InsulinDose* n = [[InsulinDose alloc] init];
	n.insulinType = t;
	return n;
}

@end
