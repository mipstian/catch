#import <Cocoa/Cocoa.h>
#import "Preferences.h"

extern NSString * const kCTCSchedulerStatusNotificationName;


@interface CTCScheduler : NSObject

- (BOOL)pauseResume;

- (void)forceCheck;

@end
