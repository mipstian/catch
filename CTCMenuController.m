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
    
    [self setupObservers];
}

- (void)setupMenuItem {
    // Create the NSStatusItem and set its length
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
    __weak typeof(self) weakSelf = self;
    
    void (^handleSchedulerStatusChange)(NSNotification *) = ^(NSNotification *notification) {
        [weakSelf refreshSchedulerStatus];
    };
    
    void (^handleSchedulerLastUpdateStatusChange)(NSNotification *) = ^(NSNotification *notification) {
        BOOL wasSuccessful = [notification.userInfo[@"successful"] boolValue];
        NSDate *lastUpdateDate = notification.userInfo[@"time"];
        [weakSelf setLastUpdateStatus:wasSuccessful time:lastUpdateDate];
        [weakSelf refreshRecentsMenu];
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

- (IBAction)openTorrentFolder:(id)sender {
    if (!CTCDefaults.isConfigurationValid) return;
    
    // Launch finder with the torrent folder open
    [NSWorkspace.sharedWorkspace openFile:CTCDefaults.torrentsSavePath];
}

- (IBAction)checkNow:(id)sender {
    [CTCScheduler.sharedScheduler forceCheck];
}

- (IBAction)togglePause:(id)sender {
    [CTCScheduler.sharedScheduler togglePause];
}

- (void)refreshSchedulerStatus {
    if (CTCScheduler.sharedScheduler.isChecking) {
        [self setRefreshing];
    }
    else {
        if (CTCScheduler.sharedScheduler.isPolling) {
            [self setIdle];
        }
        else {
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
    }
    else {
        baseLastUpdateString = NSLocalizedString(@"lastupdatefailed", @"Title for the last update time if it fails");
    }

    if (time) {
        NSDateFormatter *dateFormatter = NSDateFormatter.new;
        dateFormatter.timeStyle = NSDateFormatterShortStyle;
        NSString *lastUpdateTime = [dateFormatter stringFromDate:time];
        lastUpdateString = [NSString stringWithFormat:baseLastUpdateString, lastUpdateTime];
    }
    else {
        lastUpdateString = [NSString stringWithFormat:baseLastUpdateString, NSLocalizedString(@"never", @"Never happened")];
    }
    
    [self.menuLastUpdate setTitle:lastUpdateString];
}

- (void)setIdle {
    // Sets the images (status: idle)
    if ([self.menuBarItem respondsToSelector:@selector(button)]) {
        // Yosemite
        self.menuBarItem.button.image = [NSImage imageNamed:@"Menubar_Idle_Template"];
        self.menuBarItem.button.appearsDisabled = NO;
    }
    else {
        // Older versions of OS X
        [self.menuBarItem setImage:[NSImage imageNamed:@"menubar_idle"]];
        [self.menuBarItem setAlternateImage:[NSImage imageNamed:@"menubar_idle-inv"]];
    }
    
    // Set pause/resume to "pause"
    [self.menuPauseResume setTitle:NSLocalizedString(@"pause", @"Description of pause action")];
}

- (void)setRefreshing {
    // Sets the images (status: refreshing)
    if ([self.menuBarItem respondsToSelector:@selector(button)]) {
        // Yosemite
        self.menuBarItem.button.image = [NSImage imageNamed:@"Menubar_Refreshing_Template"];
        self.menuBarItem.button.appearsDisabled = NO;
    }
    else {
        // Older versions of OS X
        [self.menuBarItem setImage:[NSImage imageNamed:@"menubar_refreshing"]];
        [self.menuBarItem setAlternateImage:[NSImage imageNamed:@"menubar_refreshing-inv"]];
    }
    
    // Set pause/resume to "pause"
    [self.menuPauseResume setTitle:NSLocalizedString(@"pause", @"Description of pause action")];
    
    // Also overwrite the last update string with "Updating now"
    [self.menuLastUpdate setTitle:NSLocalizedString(@"updatingnow", @"An update is in progress")];
}

- (void)setDisabled {
    // Sets the images (status: disabled)
    if ([self.menuBarItem respondsToSelector:@selector(button)]) {
        // Yosemite
        self.menuBarItem.button.image = [NSImage imageNamed:@"Menubar_Disabled_Template"];
        self.menuBarItem.button.appearsDisabled = YES;
    }
    else {
        // Older versions of OS X
        [self.menuBarItem setImage:[NSImage imageNamed:@"menubar_disabled"]];
        [self.menuBarItem setAlternateImage:[NSImage imageNamed:@"menubar_disabled-inv"]];
    }
    
    // Set pause/resume to "resume"
    [self.menuPauseResume setTitle:NSLocalizedString(@"resume", @"Description of resume action")];
}

- (void)refreshRecentsMenu {
    // Also refresh the list of recently downloaded torrents
    // Get the full list
    NSArray *downloadHistory = CTCDefaults.downloadHistory;
    
    // Get last 10 elements
    NSUInteger recentsCount = MIN(downloadHistory.count, 10U);
    NSArray *recents = [downloadHistory subarrayWithRange:NSMakeRange(0U, recentsCount)];
    
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

@end
