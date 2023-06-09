#import <Cocoa/Cocoa.h>


extern NSString * const kCTCSchedulerStatusNotificationName;
extern NSString * const kCTCSchedulerLastUpdateStatusNotificationName;


@interface CTCScheduler : NSObject

@property (assign, nonatomic, readonly, getter = isPolling) BOOL polling;
@property (assign, nonatomic, readonly, getter = isChecking) BOOL checking;

+ (instancetype)sharedScheduler;

- (void)togglePause;

- (void)forceCheck;

- (void)downloadFile:(NSDictionary *)file
          completion:(void (^)(NSDictionary *downloadedFile, NSError *error))completion;

@end
