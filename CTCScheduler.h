#import <Cocoa/Cocoa.h>
#import "Preferences.h"

extern NSString * const kCTCSchedulerStatusNotificationName;
extern NSString * const kCTCSchedulerLastUpdateStatusNotificationName;


@interface CTCScheduler : NSObject

- (BOOL)pauseResume;

- (void)forceCheck;

@end
