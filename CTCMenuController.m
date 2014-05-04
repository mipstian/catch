#import "CTCMenuController.h"
#import "CTCDefaults.h"
#import "CTCScheduler.h"


@interface CTCMenuController ()

@property (strong, nonatomic) IBOutlet NSMenu *menu;
@property (strong, nonatomic) IBOutlet NSMenuItem *menuVersion;
@property (strong, nonatomic) IBOutlet NSMenuItem *menuPauseResume;
@property (strong, nonatomic) IBOutlet NSMenuItem *menuLastUpdate;
@property (strong, nonatomic) IBOutlet NSMenuItem *menuRecentTorrents;
@property (strong, nonatomic) IBOutlet NSMenuItem *menuShowInFinder;

@property (strong, nonatomic) NSStatusItem *menuBarItem;

@end


@implementation CTCMenuController

- (void)awakeFromNib {
    [self setupMenuItem];
    
	// Update UI with initial values
    [self refreshSchedulerStatus];
	[self setLastUpdateStatus:YES time:nil];

	// Enable Notification Center notifications
    [NSUserNotificationCenter.defaultUserNotificationCenter setDelegate:self];
    
    [self setupObservers];
}

- (void)setupMenuItem {
    // Create the NSStatusBar and set its length
	self.menuBarItem = [NSStatusBar.systemStatusBar statusItemWithLength:NSSquareStatusItemLength];
    
	// Tell the NSStatusItem what menu to load
    self.menuBarItem.menu = self.menu;
	// Enable highlighting
    self.menuBarItem.highlightMode = YES;
    
	// Set current name and version
	self.menuVersion.title = [NSString stringWithFormat:@"%@ %@", CTCDefaults.appName, CTCDefaults.appVersion];
	
	// Disable the recent torrents menu until there's something to show
    self.menuRecentTorrents.enabled = NO;
}

- (void)setupObservers {
    void (^handleSchedulerStatusChange)(NSNotification *) = ^(NSNotification *notification) {
        [self refreshSchedulerStatus];
    };
    
    void (^handleSchedulerLastUpdateStatusChange)(NSNotification *) = ^(NSNotification *notification) {
        BOOL wasSuccessful = [notification.userInfo[@"successful"] boolValue];
        NSDate *lastUpdateDate = notification.userInfo[@"time"];
        [self setLastUpdateStatus:wasSuccessful time:lastUpdateDate];
        [self refreshRecentsMenu];
    };
    
    [NSNotificationCenter.defaultCenter addObserverForName:kCTCSchedulerStatusNotificationName
                                                    object:CTCScheduler.sharedScheduler
                                                     queue:nil
                                                usingBlock:handleSchedulerStatusChange];
    [NSNotificationCenter.defaultCenter addObserverForName:kCTCSchedulerLastUpdateStatusNotificationName
                                                    object:CTCScheduler.sharedScheduler
                                                     queue:nil
                                                usingBlock:handleSchedulerLastUpdateStatusChange];
}

- (IBAction)browseService:(id)sender {
	// Launch the system browser, open the service (ShowRSS)
	[NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:kCTCDefaultsServiceURL]];
}

- (IBAction)browseWebsite:(id)sender {
	// Launch the system browser, open the applications's website
	[NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:kCTCDefaultsApplicationWebsiteURL]];
}

- (IBAction)browseHelp:(id)sender {
	// Launch the system browser, open the applications's on-line help
	[NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:kCTCDefaultsApplicationHelpURL]];
}

- (IBAction)browseFeatureRequest:(id)sender {
	// Launch the system browser, open the applications's feature request page
	[NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:kCTCDefaultsApplicationFeatureRequestURL]];
}

- (IBAction)browseBugReport:(id)sender {
	// Launch the system browser, open the applications's bug report page
	[NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:kCTCDefaultsApplicationBugReportURL]];
}

- (IBAction)openTorrentFolder:(id)sender {
	// Launch finder with the torrent folder open
	if (!CTCDefaults.isConfigurationValid) return;
    
    [NSWorkspace.sharedWorkspace openFile:CTCDefaults.torrentsSavePath];
}

- (IBAction)checkNow:(id)sender {
	[CTCScheduler.sharedScheduler forceCheck];
}

- (IBAction)togglePause:(id)sender {
    [CTCScheduler.sharedScheduler togglePause];
    
    // If the scheduler is now active, also force a check right away
	if (CTCScheduler.sharedScheduler.isActive) [CTCScheduler.sharedScheduler forceCheck];
}

- (IBAction)quit:(id)sender {
	NSLog(@"Quitting");
	
	// Quit
	[NSApp terminate:nil];
}

- (void)refreshSchedulerStatus {
    if (CTCScheduler.sharedScheduler.isRunning) {
        [self setRefreshing];
	} else {
		if (CTCScheduler.sharedScheduler.isActive) {
            [self setIdle];
		} else {
            [self setDisabled];
		}
	}
}

- (void)setLastUpdateStatus:(BOOL)lastUpdateWasSuccessful time:(NSDate *)time {
	// Create something like "Last update: 3:45 AM" and place it in the menu
	NSString *baseLastUpdateString = nil;
	NSString *lastUpdateString = nil;
	
	if (lastUpdateWasSuccessful) {
		baseLastUpdateString = NSLocalizedString(@"lastupdate", @"Title for the last update time");
	} else {
		baseLastUpdateString = NSLocalizedString(@"lastupdatefailed", @"Title for the last update time if it fails");
	}

	if (time) {
		NSDateFormatter *dateFormatter = NSDateFormatter.new;
        dateFormatter.timeStyle = NSDateFormatterShortStyle;
		NSString *lastUpdateTime = [dateFormatter stringFromDate:time];
		lastUpdateString = [NSString stringWithFormat:baseLastUpdateString, lastUpdateTime];
	} else {
		lastUpdateString = [NSString stringWithFormat:baseLastUpdateString, NSLocalizedString(@"never", @"Never happened")];
	}
	
    [self.menuLastUpdate setTitle:lastUpdateString];
}

- (void)setIdle {
	// Sets the images (status: idle)
	[self.menuBarItem setImage:[NSImage imageNamed:@"menubar_idle"]];
	[self.menuBarItem setAlternateImage:[NSImage imageNamed:@"menubar_idle-inv"]];
	
	// Set pause/resume to "pause"
	[self.menuPauseResume setTitle:NSLocalizedString(@"pause", @"Description of pause action")];
}

- (void)setRefreshing {
	// Sets the images (status: refreshing)
	[self.menuBarItem setImage:[NSImage imageNamed:@"menubar_refreshing"]];
	[self.menuBarItem setAlternateImage:[NSImage imageNamed:@"menubar_refreshing-inv"]];
	
	// Set pause/resume to "pause"
	[self.menuPauseResume setTitle:NSLocalizedString(@"pause", @"Description of pause action")];
	
	// Also overwrite the last update string with "Updating now"
	[self.menuLastUpdate setTitle:NSLocalizedString(@"updatingnow", @"An update is in progress")];
}

- (void)setDisabled {
	// Sets the images (status: disabled)
	[self.menuBarItem setImage:[NSImage imageNamed:@"menubar_disabled"]];
	[self.menuBarItem setAlternateImage:[NSImage imageNamed:@"menubar_disabled-inv"]];
	
	// Set pause/resume to "resume"
	[self.menuPauseResume setTitle:NSLocalizedString(@"resume", @"Description of resume action")];
}

- (void)refreshRecentsMenu {
    // Also refresh the list of recently downloaded torrents
	// Get the full list
	NSArray *downloadHistory = CTCDefaults.downloadHistory;
    
	// Get last 10 elements
    NSUInteger recentsCount = MIN(downloadHistory.count, 10U);
    NSArray *recents = [downloadHistory subarrayWithRange:NSMakeRange(downloadHistory.count - recentsCount, recentsCount)];
    
    // Extract titles
    NSArray *recentTorrentNames = [recents valueForKey:@"title"];
    
    // Clear menu
	[self.menuRecentTorrents.submenu removeAllItems];
	
	// Add new items
    [recentTorrentNames enumerateObjectsUsingBlock:^(NSString *title, NSUInteger index, BOOL *stop) {
        NSString *menuTitle = [NSString stringWithFormat:@"%lu %@", index + 1, title];
		NSMenuItem *newItem = [[NSMenuItem alloc] initWithTitle:menuTitle
                                                         action:NULL
                                                  keyEquivalent:@""];
        newItem.enabled = NO;
		[self.menuRecentTorrents.submenu addItem:newItem];
    }];
	
	// Put the Show in finder menu back
	[self.menuRecentTorrents.submenu addItem:self.menuShowInFinder];
	
    self.menuRecentTorrents.enabled = YES;
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
	 shouldPresentNotification:(NSUserNotification *)notification {
	return YES;
}

@end
