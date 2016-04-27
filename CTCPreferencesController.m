#import "CTCPreferencesController.h"
#import "CTCDefaults.h"
#import "CTCScheduler.h"
#import "NSWindow+ShakeAnimation.h"


@interface CTCPreferencesController ()
@property (weak) IBOutlet NSImageView *feedURLWarningImageView;
@property (weak) IBOutlet NSImageView *torrentsSavePathWarningImageView;
@end


@implementation CTCPreferencesController

- (void)awakeFromNib {
    [self showFeeds:self];
    
    // If the configuration isn't valid, pop up immediately
    if (!CTCDefaults.isConfigurationValid) [self showWindow:self];
    
    [NSUserDefaults.standardUserDefaults addObserver:self
                                          forKeyPath:@"savePath"
                                             options:NSKeyValueObservingOptionNew
                                             context:NULL];
    [NSUserDefaults.standardUserDefaults addObserver:self
                                          forKeyPath:@"feedURL"
                                             options:NSKeyValueObservingOptionNew
                                             context:NULL];
}

- (IBAction)showWindow:(id)sender {
    [self refreshInvalidInputMarkers];
    [NSApp activateIgnoringOtherApps:YES];
    [super showWindow:sender];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    [self refreshInvalidInputMarkers];
}

- (void)refreshInvalidInputMarkers {
    NSImage *validImage = [NSImage imageNamed:@"success"];
    NSImage *invalidImage = [NSImage imageNamed:@"warning"];
    self.torrentsSavePathWarningImageView.image = CTCDefaults.isTorrentsSavePathValid ? validImage : invalidImage;
    self.feedURLWarningImageView.image = CTCDefaults.isFeedURLValid ? validImage : invalidImage;
}

- (IBAction)savePreferences:(id)sender {
    [CTCDefaults save];
    
    if (CTCDefaults.isConfigurationValid) {
        // Hide the Preferences window
        [self.window close];
        
        // Apply the login item setting
        [CTCDefaults refreshLoginItemStatus];
        
        // Apply power management settings
        [CTCScheduler.sharedScheduler refreshActivity];
        
        // Also force check
        [CTCScheduler.sharedScheduler forceCheck];
    }
    else {
        // Show the Feeds tab because all possible invalid inputs are currently there
        [self showFeeds:self];
        
        // Shake the window to signal invalid input
        [self.window performShakeAnimation];
    }
}

- (IBAction)showFeeds:(id)sender {
    // Select the Feeds tab
    self.window.toolbar.selectedItemIdentifier = @"Feed";
}

- (IBAction)showTweaks:(id)sender {
    // Select the Tweaks tab
    self.window.toolbar.selectedItemIdentifier = @"Tweaks";
}

- (void)dealloc {
    [NSUserDefaults.standardUserDefaults removeObserver:self forKeyPath:@"savePath"];
    [NSUserDefaults.standardUserDefaults removeObserver:self forKeyPath:@"feedURL"];
}

@end
