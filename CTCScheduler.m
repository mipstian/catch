#import "CTCScheduler.h"
#import "CTCFeedChecker.h"
#import "CTCDefaults.h"
#import "CTCFileUtils.h"
#import "CTCBrowser.h"
#import "NSDate+TimeOfDayMath.h"


NSString * const kCTCSchedulerStatusChangedNotificationName = @"com.giorgiocalderolla.Catch.scheduler-status-changed";


@interface CTCScheduler ()

@property (strong, nonatomic) NSTimer *repeatingTimer;
@property (strong, nonatomic) NSXPCConnection *feedCheckerConnection;
@property (strong, nonatomic) id<NSObject> activityToken;
@property (assign, nonatomic, getter = isPolling) BOOL polling;
@property (assign, nonatomic, getter = isChecking) BOOL checking;
@property (assign, nonatomic) BOOL lastUpdateWasSuccessful;
@property (strong, nonatomic) NSDate *lastUpdateDate;

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
    self.lastUpdateWasSuccessful = YES;
    self.lastUpdateDate = nil;
  
    // Create and start single connection to the feed helper
    // Messages will be delivered serially
    self.feedCheckerConnection = [[NSXPCConnection alloc] initWithServiceName:@"com.giorgiocalderolla.Catch.CatchFeedHelper"];
    self.feedCheckerConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(CTCFeedCheck)];
    __weak typeof(self) weakSelf = self;
    self.feedCheckerConnection.interruptionHandler = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!weakSelf) return;
          
            if (weakSelf.checking) {
              [weakSelf handleFeedCheckCompletion:NO];
              NSLog(@"Feed checker service crashed");
            }
            else {
              NSLog(@"Feed checker service went offline");
            }
        });
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
    
    [self refreshActivity];
    
    return self;
}

- (void)refreshActivity {
    // Do nothing if the system doesn't support activities
    if (![NSProcessInfo.processInfo respondsToSelector:@selector(beginActivityWithOptions:reason:)]) return;
    
    // End previously started activity if any
    if (self.activityToken != nil) {
        [NSProcessInfo.processInfo endActivity:self.activityToken];
        self.activityToken = nil;
    }
    
    // No need to prevent App Nap or system sleep if paused
    if (!self.polling) return;
    
    // Prevent App Nap (so we can keep checking the feed), and optionally system sleep
    NSActivityOptions options = CTCDefaults.shouldPreventSystemSleep ?
        NSActivityIdleSystemSleepDisabled|NSActivitySuddenTerminationDisabled :
        NSActivitySuddenTerminationDisabled;
    
    self.activityToken = [NSProcessInfo.processInfo
                          beginActivityWithOptions:options
                          reason:@"Actively polling the feed"];
}

- (void)setChecking:(BOOL)checking {
    _checking = checking;
    [self sendStatusChangedNotification];
}

- (void)setPolling:(BOOL)polling {
    _polling = polling;
    
    [self refreshActivity];
    
    [self sendStatusChangedNotification];
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
  
    // Create a bookmark so we can transfer access to the downloads path
    // to the feed checker service
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
                savingMagnetLinks:!CTCDefaults.shouldOpenTorrentsAutomatically
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
    self.lastUpdateWasSuccessful = wasSuccessful;
    self.lastUpdateDate = NSDate.date;
  
    [self sendStatusChangedNotification];
}

- (void)sendStatusChangedNotification {
    [NSNotificationCenter.defaultCenter postNotificationName:kCTCSchedulerStatusChangedNotificationName
                                                      object:self
                                                    userInfo:nil];
}

- (void)togglePause {
    self.polling = !self.isPolling;
    
    // If we have just been set to polling, poll immediately
    if (self.isPolling) [self fireTimerNow];
}

- (void)forceCheck {
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
            savingMagnetLinks:!CTCDefaults.shouldOpenTorrentsAutomatically
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
    if (!self.isPolling) return;
    
    // Don't check if current time is outside user-defined range
    if (![self shouldCheckNow]) return;
    
    [self checkFeed];
}

- (void)handleDownloadedFeedFiles:(NSArray *)downloadedFeedFiles {
    BOOL shouldOpenTorrentsAutomatically = CTCDefaults.shouldOpenTorrentsAutomatically;
    
    for (NSDictionary *feedFile in downloadedFeedFiles.reverseObjectEnumerator) {
        BOOL isMagnetLink = [feedFile[@"isMagnetLink"] boolValue];
        
        // Open magnet link, if requested
        if (isMagnetLink && shouldOpenTorrentsAutomatically) {
            [CTCBrowser openInBackgroundURL:[NSURL URLWithString:feedFile[@"url"]]];
        }
        
        // Open normal torrent in torrent client, if requested
        if (!isMagnetLink && shouldOpenTorrentsAutomatically) {
            [CTCBrowser openInBackgroundFile:feedFile[@"torrentFilePath"]];
        }
        
        [self postUserNotificationForNewEpisode:feedFile[@"title"]];
        
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

- (void)postUserNotificationForNewEpisode:(NSString *)episodeTitle {
    // Post to Notification Center
    NSUserNotification *notification = NSUserNotification.new;
    notification.title = NSLocalizedString(@"newtorrent", @"New torrent notification");
    notification.informativeText = [NSString stringWithFormat:NSLocalizedString(@"newtorrentdesc", @"New torrent notification"), episodeTitle];
    notification.soundName = NSUserNotificationDefaultSoundName;
    [NSUserNotificationCenter.defaultUserNotificationCenter deliverNotification:notification];
}

- (BOOL)shouldCheckNow {
    if (!CTCDefaults.areTimeRestrictionsEnabled) return YES;
    
    return [NSDate.date isTimeOfDayBetweenDate:CTCDefaults.fromDateForTimeRestrictions
                                       andDate:CTCDefaults.toDateForTimeRestrictions];
}

@end
