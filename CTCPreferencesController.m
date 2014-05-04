#import "CTCPreferencesController.h"
#import "CTCDefaults.h"
#import "CTCScheduler.h"


@interface CTCPreferencesController ()

@property (strong, nonatomic) IBOutlet NSTabView *preferencesTabs;

@end


@implementation CTCPreferencesController

- (void)awakeFromNib {
    [self showFeeds:self];
    
    // If the configuration isn't valid, pop up immediately
    if (!CTCDefaults.isConfigurationValid) [self showPreferences:self];
}

- (IBAction)showPreferences:(id)sender {
	// Show the Preferences window
	[NSApp activateIgnoringOtherApps:YES];
	[self.window makeKeyAndOrderFront:self];
}

- (IBAction)savePreferences:(id)sender {
	// Save preferences
	[CTCDefaults save];
	
	if (CTCDefaults.isConfigurationValid) {
		// Hide the Preferences window
		[self.window close];
        
        // Also force check
        [CTCScheduler.sharedScheduler forceCheck];
	} else {
		// The feed URL is probably invalid, warn user
		[self showBadURLSheet];
	}
}

- (IBAction)showFeeds:(id)sender {
	// Select the Feeds tab
    static NSString * const FeedsTabIdentifier = @"Feeds";
    self.window.toolbar.selectedItemIdentifier = FeedsTabIdentifier;
	[self.preferencesTabs selectTabViewItemWithIdentifier:FeedsTabIdentifier];
}

- (IBAction)showTweaks:(id)sender {
	// Select the Tweaks tab
    static NSString * const TweaksTabIdentifier = @"Tweaks";
	self.window.toolbar.selectedItemIdentifier = TweaksTabIdentifier;
	[self.preferencesTabs selectTabViewItemWithIdentifier:TweaksTabIdentifier];
}

- (void)showBadURLSheet {
	[self showFeeds:self];
	
	// Show a sheet warning the user: the feed URL is invalid
	NSBeginAlertSheet(
					  NSLocalizedString(@"badurl", @"Message for bad feed URL in preferences"),
					  NSLocalizedString(@"badurlok", @"OK Button for bad feed URL in preferences"),
					  nil,
                      nil,
                      self.window,
                      self,
					  NULL,
                      NULL,
					  nil,
                      @"");
}

@end
