#import "CTCPreferencesController.h"
#import "CTCDefaults.h"
#import "CTCScheduler.h"


@implementation CTCPreferencesController

- (void)awakeFromNib {
    [self showFeeds:self];
    
    // If the configuration isn't valid, pop up immediately
    if (!CTCDefaults.isConfigurationValid) [self showWindow:self];
}

- (void)showWindow:(id)sender {
    [NSApp activateIgnoringOtherApps:YES];
    [super showWindow:sender];
}

- (IBAction)savePreferences:(id)sender {
	// Save preferences
	[CTCDefaults save];
	
    // If the feed URL is invalid, just warn user
    if (!CTCDefaults.isConfigurationValid) {
		[self showBadURLAlert];
        return;
    }
    
    // Hide the Preferences window
    [self.window close];
    
    // Also force check
    [CTCScheduler.sharedScheduler forceCheck];
}

- (IBAction)showFeeds:(id)sender {
	// Select the Feeds tab
    self.window.toolbar.selectedItemIdentifier = @"Feeds";
}

- (IBAction)showTweaks:(id)sender {
	// Select the Tweaks tab
	self.window.toolbar.selectedItemIdentifier = @"Tweaks";
}

- (void)showBadURLAlert {
	[self showFeeds:self];
    
    // Show an alert warning the user: the feed URL is invalid
    NSAlert *badURLAlert = NSAlert.new;
    badURLAlert.messageText = NSLocalizedString(@"badurl", @"Message for bad feed URL in preferences");
    badURLAlert.alertStyle = NSWarningAlertStyle;
    
    [badURLAlert beginSheetModalForWindow:self.window
                        completionHandler:NULL];
}

@end
