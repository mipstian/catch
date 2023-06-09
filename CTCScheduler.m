#import "CTCScheduler.h"
#import "CTCFeedChecker.h"
#import "CTCDefaults.h"
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
    
    self.polling = YES;
    self.checking = NO;
    
    // Create and start single connection to the feed helper
    // Messages will be delivered serially
    self.feedCheckerConnection = [[NSXPCConnection alloc] initWithServiceName:@"com.giorgiocalderolla.Catch.CatchFeedHelper"];
    self.feedCheckerConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(CTCFeedCheck)];
    __weak typeof(self) weakSelf = self;
    self.feedCheckerConnection.interruptionHandler = ^{
        [weakSelf handleFeedCheckCompletion:NO];
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
    
    [self preventAppNap];
    
    return self;
}

- (void)preventAppNap {
    // Make sure we can keep running in the background if the system supports App Nap
    if ([NSProcessInfo.processInfo respondsToSelector:@selector(beginActivityWithOptions:reason:)]) {
        self.activityToken = [NSProcessInfo.processInfo
                              beginActivityWithOptions:NSActivityIdleSystemSleepDisabled|NSActivitySuddenTerminationDisabled
                              reason:@"Background checking is the whole point of the app"];
    }
}

- (void)setChecking:(BOOL)checking {
    _checking = checking;
    [self reportStatus];
}

- (void)setPolling:(BOOL)polling {
    _polling = polling;
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
        [weakSelf handleDownloadedFeedFiles:downloadedFeedFiles];
        
        [weakSelf handleFeedCheckCompletion:error == nil];
    }];
}

- (void)callFeedCheckerWithReplyHandler:(CTCFeedCheckCompletionHandler)replyHandler {
    // Read configuration
    NSURL *feedURL = [NSURL URLWithString:CTCDefaults.feedURL];
    NSString *downloadPath = CTCDefaults.torrentsSavePath;
    BOOL organizeByFolder = CTCDefaults.shouldOrganizeTorrentsInFolders;
    NSArray *history = CTCDefaults.downloadHistory;
    
    // Extract URLs from history
    NSArray *previouslyDownloadedURLs = [history valueForKey:@"url"];
    
    // Create a bookmark so we can transfer access to the downloads path
    // to the feed checker service
    NSURL *downloadFolderURL = [NSURL fileURLWithPath:downloadPath];
    NSError *error = nil;
    NSData *downloadFolderBookmark = [downloadFolderURL bookmarkDataWithOptions:NSURLBookmarkCreationMinimalBookmark
                                                 includingResourceValuesForKeys:@[]
                                                                  relativeToURL:nil
                                                                          error:&error];
    if (!downloadFolderBookmark || error) {
        NSLog(@"Couldn't create bookmark for downloads folder: %@", error);
        
        // Not really handling this error
        return;
    }
    
    // Call feed checker service
    CTCFeedChecker *feedChecker = [self.feedCheckerConnection remoteObjectProxy];
    [feedChecker checkShowRSSFeed:feedURL
            downloadingToBookmark:downloadFolderBookmark
               organizingByFolder:organizeByFolder
                     skippingURLs:previouslyDownloadedURLs
                        withReply:^(NSArray *downloadedFeedFiles, NSError *error) {
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
            [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:feedFile[@"url"]]];
        }
        
        // Open normal torrent in torrent client, if requested
        if (!isMagnetLink && shouldOpenTorrentsAutomatically) {
            [NSWorkspace.sharedWorkspace openFile:feedFile[@"torrentFilePath"]];
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
