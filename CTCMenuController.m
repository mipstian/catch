#import "CTCMenuController.h"
#import "CTCDefaults.h"
#import "CTCScheduler.h"


@interface CTCMenuController ()

@property (strong, nonatomic) IBOutlet NSMenu *menu;
@property (strong, nonatomic) IBOutlet NSMenuItem *menuVersion;
@property (strong, nonatomic) IBOutlet NSMenuItem *menuPauseResume;
@property (strong, nonatomic) IBOutlet NSMenuItem *menuLastUpdate;

@property (strong, nonatomic) NSStatusItem *menuBarItem;

@property (strong, nonatomic) NSDateFormatter *lastUpdateDateFormatter;

@end


@implementation CTCMenuController

- (void)awakeFromNib {
    // Create a date formatter for "last update" dates
    self.lastUpdateDateFormatter = NSDateFormatter.new;
    self.lastUpdateDateFormatter.timeStyle = NSDateFormatterShortStyle;
    
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
    NSString *lastUpdateStatusFormat = lastUpdateWasSuccessful ?
        NSLocalizedString(@"lastupdate", @"Title for the last update time") :
        NSLocalizedString(@"lastupdatefailed", @"Title for the last update time if it fails");
    
    NSString *lastUpdateStatus = time ?
        [NSString stringWithFormat:lastUpdateStatusFormat,
         [self.lastUpdateDateFormatter stringFromDate:time]] :
        [NSString stringWithFormat:lastUpdateStatusFormat, NSLocalizedString(@"never", @"Never happened")];
    
    [self.menuLastUpdate setTitle:lastUpdateStatus];
}

- (void)setIdle {
    // Sets the images (status: idle)
    if (self.shouldUseTemplateMenubarIcons) {
        self.menuBarItem.button.image = [NSImage imageNamed:@"Menubar_Idle_Template"];
        self.menuBarItem.button.appearsDisabled = NO;
    }
    else {
        [self.menuBarItem setImage:[NSImage imageNamed:@"menubar_idle"]];
        [self.menuBarItem setAlternateImage:[NSImage imageNamed:@"menubar_idle-inv"]];
    }
    
    // Set pause/resume to "pause"
    [self.menuPauseResume setTitle:NSLocalizedString(@"pause", @"Description of pause action")];
}

- (void)setRefreshing {
    // Sets the images (status: refreshing)
    if (self.shouldUseTemplateMenubarIcons) {
        self.menuBarItem.button.image = [NSImage imageNamed:@"Menubar_Refreshing_Template"];
        self.menuBarItem.button.appearsDisabled = NO;
    }
    else {
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
    if (self.shouldUseTemplateMenubarIcons) {
        self.menuBarItem.button.image = [NSImage imageNamed:@"Menubar_Disabled_Template"];
        self.menuBarItem.button.appearsDisabled = YES;
    }
    else {
        [self.menuBarItem setImage:[NSImage imageNamed:@"menubar_disabled"]];
        [self.menuBarItem setAlternateImage:[NSImage imageNamed:@"menubar_disabled-inv"]];
    }
    
    // Set pause/resume to "resume"
    [self.menuPauseResume setTitle:NSLocalizedString(@"resume", @"Description of resume action")];
}

- (BOOL)shouldUseTemplateMenubarIcons {
    // Use template images in Yosemite and up, plain icons otherwise
    return [self.menuBarItem respondsToSelector:@selector(button)];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

@end
