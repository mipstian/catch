#import <Cocoa/Cocoa.h>


extern NSString * const kCTCSchedulerStatusNotificationName;
extern NSString * const kCTCSchedulerLastUpdateStatusNotificationName;


@interface CTCScheduler : NSObject

- (BOOL)pauseResume;

- (void)forceCheck;

@end
