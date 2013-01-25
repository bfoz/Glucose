#import "FlurryLogger.h"

#import "Flurry.h"

NSString* kFlurryEventNewLogEntryDidCancelTimestamp = @"FlurryEventNewLogEntryDidChangeTimestamp";
NSString* kFlurryEventNewLogEntryDidChangeTimestamp = @"FlurryEventNewLogEntryDidChangeTimestamp";
NSString* kFlurryEventNewLogEntryDidTapTimestamp    = @"FlurryEventNewLogEntryDidTapTimestamp";

static FlurryLogger*	__currentFLurryLogger = nil;

@implementation FlurryLogger

+ (FlurryLogger*) currentFlurryLogger
{
    if( !__currentFLurryLogger )
	__currentFLurryLogger = [[FlurryLogger alloc] init];
    return __currentFLurryLogger;
}

- (void) logEventWithName:(NSString *)eventName
{
    [self logEventWithName:(NSString *)eventName withParameters:nil timed:NO];
}

- (void) logEventWithName:(NSString *)eventName withParameters:(NSDictionary *)parameterDictionary timed:(BOOL)timed
{
#ifndef SPECS
    [Flurry logEvent:eventName withParameters:parameterDictionary timed:timed];
#endif
}

@end
