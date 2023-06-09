#import "CTCScheduler.h"
#import "CTCFeedChecker.h"
#import "CTCDefaults.h"
#import "NSDate+TimeOfDayMath.h"


NSString * const kCTCSchedulerStatusNotificationName = @"com.giorgiocalderolla.Catch.scheduler-status-update";
NSString * const kCTCSchedulerLastUpdateStatusNotificationName = @"com.giorgiocalderolla.Catch.scheduler-last-update-status-update";


@interface CTCScheduler ()

@property (strong, nonatomic) NSTimer *repeatingTimer;
@property (strong, nonatomic) NSXPCConnection *feedCheckerConnection;
@property (assign, nonatomic, getter = isActive) BOOL active;
@property (assign, nonatomic, getter = isRunning) BOOL running;

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
    
	self.active = YES;
	self.running = NO;
    
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
    
    // Fire the timer ASAP
    [self.repeatingTimer setFireDate:NSDate.distantPast];
	
	return self;
}

- (void)callFeedCheckerWithReplyHandler:(CTCFeedCheckCompletionHandler)replyHandler {
    // Read configuration
    NSURL *feedURL = [NSURL URLWithString:CTCDefaults.feedURL];
    NSString *downloadPath = CTCDefaults.torrentsSavePath;
    BOOL organizeByFolder = CTCDefaults.shouldOrganizeTorrentsInFolders;
    NSArray *history = CTCDefaults.downloadHistory;
    
    // Extract URLs from history
    NSArray *previouslyDownloadedURLs = [history valueForKey:@"url"];
    
    // Call feed checker service
    CTCFeedChecker *feedChecker = [self.feedCheckerConnection remoteObjectProxy];
    [feedChecker checkShowRSSFeed:feedURL
                downloadingToPath:downloadPath
               organizingByFolder:organizeByFolder
                     skippingURLs:previouslyDownloadedURLs
                        withReply:replyHandler];
}

- (void)checkFeed {
	// Only work with valid preferences
	if (!CTCDefaults.isConfigurationValid) {
		NSLog(@"Refusing to check feed - invalid preferences");
		return;
	}
    
    // Don't check twice simultaneously
    if (self.isRunning) return;
	
	self.running = YES;
	
    [self reportStatus];
	
    [self callFeedCheckerWithReplyHandler:^(NSArray *downloadedFeedFiles,
                                            NSError *error){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self handleFeedCheckCompletion:error == nil];
            
            // Deal with new files
            [self handleDownloadedFeedFiles:downloadedFeedFiles];
        });
    }];
}

- (void)handleFeedCheckCompletion:(BOOL)wasSuccessful {
    self.running = NO;
    
    [self reportStatus];
    [NSNotificationCenter.defaultCenter postNotificationName:kCTCSchedulerLastUpdateStatusNotificationName
                                                      object:self
                                                    userInfo:@{@"successful": @(wasSuccessful),
                                                               @"time": NSDate.date}];
}

- (void)reportStatus {
	NSLog(@"Scheduler status: active = %d, running = %d", self.isActive, self.isRunning);
	
	// Report status to application delegate
    [NSNotificationCenter.defaultCenter postNotificationName:kCTCSchedulerStatusNotificationName
                                                      object:self
                                                    userInfo:nil];
}

- (void)togglePause {
	self.active = !self.isActive;
	
    [self reportStatus];
    
    // If we have just been set to active, check right now
    if (self.isActive) [self.repeatingTimer setFireDate:NSDate.distantPast];
}

- (void)forceCheck {
	NSLog(@"Forcing feed check");
    
	// Check feed right now ignoring time restrictions and "paused" mode
	[self checkFeed];
}

- (void)tick:(NSTimer*)timer {
	NSLog(@"Scheduler tick");
	
	if (!self.isActive) {
		NSLog(@"Scheduler tick skipped (paused)");
		return;
	}
	
	// Don't check if current time is outside user-defined range
	if (CTCDefaults.areTimeRestrictionsEnabled && ![self checkTime]) {
        NSLog(@"Scheduler tick skipped (outside of user-defined time range)");
        return;
	}
    
    [self checkFeed];
}

- (void)handleDownloadedFeedFiles:(NSArray *)downloadedFeedFiles {
    BOOL shouldOpenTorrentsAutomatically = CTCDefaults.shouldOpenTorrentsAutomatically;
    BOOL shouldSendNotifications = CTCDefaults.shouldSendNotifications;
    
    for (NSDictionary *feedFile in downloadedFeedFiles) {
        BOOL isMagnetLink = [feedFile[@"isMagnetLink"] boolValue];
        
        // Open magnet link
        if (isMagnetLink) {
            [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:feedFile[@"url"]]];
        }
        
        // Open normal torrent in torrent client, if requested
        if (!isMagnetLink && shouldOpenTorrentsAutomatically) {
            [NSWorkspace.sharedWorkspace openFile:feedFile[@"torrentFilePath"]];
        }
        
        // Post to Notification Center if requested
        if (shouldSendNotifications) {
            NSString *description = [NSString stringWithFormat:NSLocalizedString(@"newtorrentdesc", @"New torrent notification"), feedFile[@"title"]];
            
            NSUserNotification *notification = NSUserNotification.new;
            notification.title = NSLocalizedString(@"newtorrent", @"New torrent notification");
            notification.informativeText = description;
            notification.soundName = NSUserNotificationDefaultSoundName;
            [NSUserNotificationCenter.defaultUserNotificationCenter deliverNotification:notification];
        }
        
        // Add url to history
        NSArray *history = CTCDefaults.downloadHistory;
        NSArray *newHistory = [history arrayByAddingObject:@{@"title": feedFile[@"title"],
                                                             @"url": feedFile[@"url"]}];
        CTCDefaults.downloadHistory = newHistory;
    }
}

- (BOOL)checkTime {
    return [NSDate.date isTimeOfDayBetweenDate:CTCDefaults.fromDateForTimeRestrictions
                                       andDate:CTCDefaults.toDateForTimeRestrictions];
}

@end
