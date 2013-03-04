#import <Foundation/Foundation.h>

extern NSString* kFlurryEventNewLogEntryDidCancelTimestamp;
extern NSString* kFlurryEventNewLogEntryDidChangeTimestamp;
extern NSString* kFlurryEventNewLogEntryDidTapTimestamp;

@interface FlurryLogger : NSObject

+ (FlurryLogger*) currentFlurryLogger;

+ (void) logError:(NSString*)title message:(NSString*)message error:(NSError*)error;

- (void) logError:(NSString*)title message:(NSString*)message error:(NSError*)error;
- (void) logEventWithName:(NSString *)eventName;

@end
