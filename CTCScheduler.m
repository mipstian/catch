#import "CTCScheduler.h"
#import "CTCFeedChecker.h"
#import "CTCDefaults.h"
#import "CTCFileUtils.h"
#import "CTCBrowser.h"
#import "NSDate+TimeOfDayMath.h"


NSString * const kCTCSchedulerStatusNotificationName = @"com.giorgiocalderolla.Catch.scheduler-status-update";
NSString * const kCTCSchedulerLastUpdateStatusNotificationName = @"com.giorgiocalderolla.Catch.scheduler-last-update-status-update";


@interface CTCScheduler ()

@property (strong, nonatomic) NSTimer *repeatingTimer;
@property (strong, nonatomic) NSXPCConnection *feedCheckerConnection;
@property (strong, nonatomic) id<NSObject> activityToken;
@property (assign, nonatomic, getter = isPolling) BOOL polling;
@property (assign, nonatomic, getter = isChecking) BOOL checking;

@end


@implementation CTCScheduler

+ (instancetype)sharedScheduler {
    static CTCScheduler *sharedScheduler = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedScheduler = CTCScheduler.new;
    });
    
    return sharedScheduler;
}

- (id)init {
    self = [super init];
    if (!self) {
        return nil;
    }
  
    self.activityToken = nil;
    self.polling = YES;
    self.checking = NO;
    
    // Create and start single connection to the feed helper
    // Messages will be delivered serially
    self.feedCheckerConnection = [[NSXPCConnection alloc] initWithServiceName:@"com.giorgiocalderolla.Catch.CatchFeedHelper"];
    self.feedCheckerConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(CTCFeedCheck)];
    self.feedCheckerConnection.interruptionHandler = ^{
        NSLog(@"Feed checker service went offline");
    };
    [self.feedCheckerConnection resume];
    
    // Create a timer to check periodically
    self.repeatingTimer = [NSTimer scheduledTimerWithTimeInterval:kCTCDefaultsFeedUpdateInterval
                                                           target:self
                                                         selector:@selector(tick:)
                                                         userInfo:nil
                                                          repeats:YES];
    
    // Check now as well
    [self fireTimerNow];
    
    [self updateAppNapStatus];
    
    return self;
}

- (void)preventAppNap {
    // Make sure we can keep running in the background if the system supports App Nap
    if ([NSProcessInfo.processInfo respondsToSelector:@selector(beginActivityWithOptions:reason:)]) {
        self.activityToken = [NSProcessInfo.processInfo
                              beginActivityWithOptions:NSActivityIdleSystemSleepDisabled|NSActivitySuddenTerminationDisabled
                              reason:@"Actively polling the feed"];
    }
}

- (void)allowAppNap {
  // Make sure we can keep running in the background if the system supports App Nap
  if ([NSProcessInfo.processInfo respondsToSelector:@selector(beginActivityWithOptions:reason:)] && self.activityToken) {
      [NSProcessInfo.processInfo endActivity:self.activityToken];
      self.activityToken = nil;
  }
}

- (void)updateAppNapStatus {
    self.polling ? [self preventAppNap] : [self allowAppNap];
}

- (void)setChecking:(BOOL)checking {
    _checking = checking;
    [self reportStatus];
}

- (void)setPolling:(BOOL)polling {
    _polling = polling;
    
    [self updateAppNapStatus];
    
    [self reportStatus];
}

- (void)checkFeed {
    // Don't check twice simultaneously
    if (self.isChecking) return;
    
    // Only work with valid preferences
    if (!CTCDefaults.isConfigurationValid) {
        NSLog(@"Refusing to check feed - invalid preferences");
        return;
    }
    
    self.checking = YES;
    
    // Check the feed
    __weak typeof(self) weakSelf = self;
    [self callFeedCheckerWithReplyHandler:^(NSArray *downloadedFeedFiles,
                                            NSError *error){
        // Deal with new files
        if (weakSelf) {
            [weakSelf handleDownloadedFeedFiles:downloadedFeedFiles];
            
            [weakSelf handleFeedCheckCompletion:error == nil];
        }
    }];
}

- (NSData *)downloadFolderBookmark {
    NSError *error;
    NSURL *url = [NSURL fileURLWithPath:CTCDefaults.torrentsSavePath];
    NSData *bookmark = [CTCFileUtils bookmarkForURL:url error:&error];
    
    if (!bookmark) {
        // Not really handling this at all
        [NSException raise:@"Couldn't create bookmark for downloads folder"
                    format:@"Error: %@", error];
    }
    
    return bookmark;
}

- (void)callFeedCheckerWithReplyHandler:(CTCFeedCheckCompletionHandler)replyHandler {
    // Read configuration
    NSURL *feedURL = [NSURL URLWithString:CTCDefaults.feedURL];
    
    NSArray *history = CTCDefaults.downloadHistory;
    
    // Extract URLs from history
    NSArray *previouslyDownloadedURLs = [history valueForKey:@"url"];
    
    // Call feed checker service
    CTCFeedChecker *feedChecker = [self.feedCheckerConnection remoteObjectProxy];
    [feedChecker checkShowRSSFeed:feedURL
            downloadingToBookmark:[self downloadFolderBookmark]
               organizingByFolder:CTCDefaults.shouldOrganizeTorrentsInFolders
                     skippingURLs:previouslyDownloadedURLs
                        withReply:^(NSArray *downloadedFeedFiles, NSError *error) {
                            if (error) {
                                NSLog(@"Feed Checker error (checking feed): %@", error);
                            }
                            dispatch_async(dispatch_get_main_queue(), ^{
                                replyHandler(downloadedFeedFiles, error);
                            });
                        }];
}

- (void)handleFeedCheckCompletion:(BOOL)wasSuccessful {
    self.checking = NO;
    
    [NSNotificationCenter.defaultCenter postNotificationName:kCTCSchedulerLastUpdateStatusNotificationName
                                                      object:self
                                                    userInfo:@{@"successful": @(wasSuccessful),
                                                               @"time": NSDate.date}];
}

- (void)reportStatus {
    NSLog(@"Scheduler status updated (polling = %d, checking = %d)", self.isPolling, self.isChecking);
    
    // Report status to application delegate
    [NSNotificationCenter.defaultCenter postNotificationName:kCTCSchedulerStatusNotificationName
                                                      object:self
                                                    userInfo:nil];
}

- (void)togglePause {
    self.polling = !self.isPolling;
    
    // If we have just been set to polling, poll immediately
    if (self.isPolling) [self fireTimerNow];
}

- (void)forceCheck {
    NSLog(@"Forcing feed check");
    
    // Check feed right now ignoring time restrictions and "paused" mode
    [self checkFeed];
}

- (void)downloadFile:(NSDictionary *)file
          completion:(void (^)(NSDictionary *downloadedFile, NSError *error))completion {
    // Call feed checker service
    CTCFeedChecker *feedChecker = [self.feedCheckerConnection remoteObjectProxy];
    [feedChecker downloadFile:file
                   toBookmark:[self downloadFolderBookmark]
           organizingByFolder:CTCDefaults.shouldOrganizeTorrentsInFolders
                    withReply:^(NSDictionary *downloadedFile, NSError *error) {
                        if (error) {
                            NSLog(@"Feed Checker error (downloading file): %@", error);
                        }
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completion(downloadedFile, error);
                        });
    }];
}

- (void)fireTimerNow {
    [self.repeatingTimer setFireDate:NSDate.distantPast];
}

- (void)tick:(NSTimer*)timer {
    NSLog(@"Scheduler tick");
    
    if (!self.isPolling) {
        NSLog(@"Scheduler tick skipped (paused)");
        return;
    }
    
    // Don't check if current time is outside user-defined range
    if (![self shouldCheckNow]) {
        NSLog(@"Scheduler tick skipped (outside of user-defined time range)");
        return;
    }
    
    [self checkFeed];
}

- (void)handleDownloadedFeedFiles:(NSArray *)downloadedFeedFiles {
    BOOL shouldOpenTorrentsAutomatically = CTCDefaults.shouldOpenTorrentsAutomatically;
    
    for (NSDictionary *feedFile in downloadedFeedFiles.reverseObjectEnumerator) {
        BOOL isMagnetLink = [feedFile[@"isMagnetLink"] boolValue];
        
        // Open magnet link
        if (isMagnetLink) {
            [CTCBrowser openInBackgroundURL:[NSURL URLWithString:feedFile[@"url"]]];
        }
        
        // Open normal torrent in torrent client, if requested
        if (!isMagnetLink && shouldOpenTorrentsAutomatically) {
            [CTCBrowser openInBackgroundFile:feedFile[@"torrentFilePath"]];
        }
        
        // Post to Notification Center
        NSUserNotification *notification = NSUserNotification.new;
        notification.title = NSLocalizedString(@"newtorrent", @"New torrent notification");
        notification.informativeText = [NSString stringWithFormat:NSLocalizedString(@"newtorrentdesc", @"New torrent notification"), feedFile[@"title"]];
        notification.soundName = NSUserNotificationDefaultSoundName;
        [NSUserNotificationCenter.defaultUserNotificationCenter deliverNotification:notification];
        
        // Add url to history
        NSArray *history = CTCDefaults.downloadHistory;
        NSDictionary *newHistoryEntry = @{@"title": feedFile[@"title"],
                                          @"url": feedFile[@"url"],
                                          @"isMagnetLink": feedFile[@"isMagnetLink"],
                                          @"date": NSDate.date};
        NSArray *newHistory = [@[newHistoryEntry] arrayByAddingObjectsFromArray:history];
        CTCDefaults.downloadHistory = newHistory;
    }
}

- (BOOL)shouldCheckNow {
    if (!CTCDefaults.areTimeRestrictionsEnabled) return YES;
    
    return [NSDate.date isTimeOfDayBetweenDate:CTCDefaults.fromDateForTimeRestrictions
                                       andDate:CTCDefaults.toDateForTimeRestrictions];
}

@end
