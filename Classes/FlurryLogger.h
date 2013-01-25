#import <Foundation/Foundation.h>

extern NSString* kFlurryEventNewLogEntryDidCancelTimestamp;
extern NSString* kFlurryEventNewLogEntryDidChangeTimestamp;
extern NSString* kFlurryEventNewLogEntryDidTapTimestamp;

@interface FlurryLogger : NSObject

+ (FlurryLogger*) currentFlurryLogger;

- (void) logEventWithName:(NSString *)eventName;

@end
