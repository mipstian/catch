#import <Cocoa/Cocoa.h>


extern NSString * const kCTCSchedulerStatusChangedNotificationName;


@interface CTCScheduler : NSObject

@property (assign, nonatomic, readonly, getter = isPolling) BOOL polling;
@property (assign, nonatomic, readonly, getter = isChecking) BOOL checking;

/// True iff the last feed check succeeded, or if no check has been made yet.
@property (assign, nonatomic, readonly) BOOL lastUpdateWasSuccessful;

/// The date/time of the last feed check, nil if no check has been made yet.
@property (strong, nonatomic, readonly) NSDate *lastUpdateDate;

+ (instancetype)sharedScheduler;

- (void)togglePause;

- (void)forceCheck;

- (void)downloadFile:(NSDictionary *)file
          completion:(void (^)(NSDictionary *downloadedFile, NSError *error))completion;

@end
