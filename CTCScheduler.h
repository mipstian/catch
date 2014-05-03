#import <Cocoa/Cocoa.h>


extern NSString * const kCTCSchedulerStatusNotificationName;
extern NSString * const kCTCSchedulerLastUpdateStatusNotificationName;


@interface CTCScheduler : NSObject

@property (assign, nonatomic, readonly, getter = isActive) BOOL active;
@property (assign, nonatomic, readonly, getter = isRunning) BOOL running;

- (void)togglePause;

- (void)forceCheck;

@end
