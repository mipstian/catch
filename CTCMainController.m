#import "CTCMainController.h"
#import "CTCDefaults.h"
#import "CTCScheduler.h"


@interface CTCMainController ()
@property (strong, nonatomic) IBOutlet NSMenu *menu;
@property (strong, nonatomic) IBOutlet NSMenuItem *menuVersion;
@property (strong, nonatomic) IBOutlet NSMenuItem *menuPauseResume;
@property (strong, nonatomic) IBOutlet NSMenuItem *menuLastUpdate;
@property (strong, nonatomic) IBOutlet NSMenuItem *menuRecentTorrents;
@property (strong, nonatomic) IBOutlet NSMenuItem *menuShowInFinder;
@property (strong, nonatomic) IBOutlet NSWindow *preferencesWindow;
@property (strong, nonatomic) IBOutlet NSTabView *preferencesTabs;

@property (strong, nonatomic) NSStatusItem *menuBarItem;

@property (strong, nonatomic) CTCScheduler *scheduler;
@end


@implementation CTCMainController

- (void)awakeFromNib {
    self.scheduler = CTCScheduler.new;
    
    [self setupMenuItem];
    
	// Update UI with initial dummy values
	[self setSchedulerStatusActive:YES running:NO];
	[self setLastUpdateStatus:YES time:nil];

	// Enable Notification Center notifications
    [NSUserNotificationCenter.defaultUserNotificationCenter setDelegate:self];
	
	// Select the first tab of the Preferences
	[self showFeeds:self];
    
    [self setupNotificationHandlers];
}

- (void)setupMenuItem {
    // Create the NSStatusBar and set its length
	self.menuBarItem = [NSStatusBar.systemStatusBar statusItemWithLength:NSSquareStatusItemLength];
    
    NSString *appNameAndVersion = [NSString stringWithFormat:@"%@ %@", CTCDefaults.appName, CTCDefaults.appVersion];
    
	// Tell the NSStatusItem what menu to load
	[self.menuBarItem setMenu:self.menu];
	// Set the tooptip for our item
	[self.menuBarItem setToolTip:appNameAndVersion];
	// Enable highlighting
	[self.menuBarItem setHighlightMode:YES];
	// Set current name and version
	[self.menuVersion setTitle:appNameAndVersion];
	
	// Disable the recent torrents menu until there's something to show
	[self.menuRecentTorrents setEnabled:NO];
}

- (void)setupNotificationHandlers {
    void (^handleSchedulerStatusChange)(NSNotification *) = ^(NSNotification *notification) {
        BOOL isSchedulerActive = [notification.userInfo[@"isActive"] boolValue];
        BOOL isSchedulerRunning = [notification.userInfo[@"isRunning"] boolValue];
        [self setSchedulerStatusActive:isSchedulerActive running:isSchedulerRunning];
    };
    
    void (^handleSchedulerLastUpdateStatusChange)(NSNotification *) = ^(NSNotification *notification) {
        BOOL wasSuccessful = [notification.userInfo[@"successful"] boolValue];
        NSDate *lastUpdateDate = notification.userInfo[@"time"];
        [self setLastUpdateStatus:wasSuccessful time:lastUpdateDate];
        [self refreshRecentsMenu];
    };
    
    [NSNotificationCenter.defaultCenter addObserverForName:kCTCSchedulerStatusNotificationName
                                                    object:self.scheduler
                                                     queue:nil
                                                usingBlock:handleSchedulerStatusChange];
    [NSNotificationCenter.defaultCenter addObserverForName:kCTCSchedulerLastUpdateStatusNotificationName
                                                    object:self.scheduler
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
    
    NSString *torrentFolder = CTCDefaults.torrentsSavePath;
    [NSWorkspace.sharedWorkspace openFile:torrentFolder.stringByStandardizingPath];
}

- (IBAction)showPreferences:(id)sender {
	// Show the Preferences window
	[NSApp activateIgnoringOtherApps:YES];
	[self.preferencesWindow makeKeyAndOrderFront:self];
}

- (IBAction)savePreferences:(id)sender {
	// Save preferences
	[CTCDefaults save];
	
	if (CTCDefaults.isConfigurationValid) {
		// Hide the Preferences window
		[self.preferencesWindow close];
        
        // Also force check
        [self forceCheck];
	} else {
		// The feed URL is probably invalid, warn user
		[self showBadURLSheet];
	}
}

- (IBAction)showFeeds:(id)sender {
	// Select the Feeds tab
    self.preferencesWindow.toolbar.selectedItemIdentifier = @"Feeds";
	[self.preferencesTabs selectFirstTabViewItem:self];
}

- (IBAction)showTweaks:(id)sender {
	// Select the Tweaks tab
	self.preferencesWindow.toolbar.selectedItemIdentifier = @"Tweaks";
	[self.preferencesTabs selectLastTabViewItem:self];
}

- (void)forceCheck {
    [self.scheduler forceCheck];
}

- (IBAction)checkNow:(id)sender {
	[self forceCheck];
}

- (IBAction)togglePause:(id)sender {
    [self.scheduler togglePause];
    
    // If the scheduler is now active, also force a check right away
	if (self.scheduler.isActive) [self.scheduler forceCheck];
}

- (IBAction)quit:(id)sender {
	NSLog(@"Quitting");
    
	// Save preferences
	[CTCDefaults save];
	
	// Quit
	[NSApp terminate:nil];
}

- (void)setSchedulerStatusActive:(BOOL)isActive running:(BOOL)isRunning {
	if (isRunning) {
        [self setRefreshing];
	} else {
		if (isActive) {
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
	
    [self setMenuLastUpdateStatus:lastUpdateString];
}

- (void)setMenuLastUpdateStatus:(NSString*)title {
	[self.menuLastUpdate setTitle:title];
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
	NSArray *downloaded = CTCDefaults.downloadHistory;
    
	// Get last 10 elements
	NSRange recentRange;
	recentRange.length = (downloaded.count > 10) ? 10 : downloaded.count;
	recentRange.location = downloaded.count - recentRange.length;
	NSArray *recents = [downloaded subarrayWithRange:recentRange];
    
    // Extract titles
    NSMutableArray *recentTorrentNames = NSMutableArray.array;
    for (NSDictionary *recentItem in recents) {
        [recentTorrentNames addObject:recentItem[@"title"]];
    }
    
    // Clear menu
	[self.menuRecentTorrents.submenu removeAllItems];
	
	// Add new items
	for (NSString *title in recentTorrentNames) {
        NSString *menuTitle = [NSString stringWithFormat:@"%lu %@", (unsigned long)[recentTorrentNames indexOfObject:title] + 1, title];
		NSMenuItem *newItem = [[NSMenuItem alloc] initWithTitle:menuTitle
                                                         action:NULL
                                                  keyEquivalent:@""];
        newItem.enabled = NO;
		[self.menuRecentTorrents.submenu addItem:newItem];
	}
	
	// Put the Show in finder menu back
	[self.menuRecentTorrents.submenu addItem:self.menuShowInFinder];
	
    self.menuRecentTorrents.enabled = YES;
}

- (void)showBadURLSheet {
	[self showFeeds:self];
	
	// Show a sheet warning the user: the feed URL is invalid
	NSBeginAlertSheet(
					  NSLocalizedString(@"badurl", @"Message for bad feed URL in preferences"),
					  NSLocalizedString(@"badurlok", @"OK Button for bad feed URL in preferences"),
					  nil,
                      nil,
                      self.preferencesWindow,
                      self,
					  NULL,
                      NULL,
					  nil,
                      @"");
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
	 shouldPresentNotification:(NSUserNotification *)notification {
	return YES;
}

@end
