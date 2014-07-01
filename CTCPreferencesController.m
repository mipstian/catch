#import "CTCPreferencesController.h"
#import "CTCDefaults.h"
#import "CTCScheduler.h"
#import "NSWindow+ShakeAnimation.h"


@implementation CTCPreferencesController

- (void)awakeFromNib {
    [self showFeeds:self];
    
    // If the configuration isn't valid, pop up immediately
    if (!CTCDefaults.isConfigurationValid) [self showWindow:self];
}

- (IBAction)showWindow:(id)sender {
    [NSApp activateIgnoringOtherApps:YES];
    [super showWindow:sender];
}

- (IBAction)savePreferences:(id)sender {
	[CTCDefaults save];
	
    if (CTCDefaults.isConfigurationValid) {
        // Hide the Preferences window
        [self.window close];
        
        // Also force check
        [CTCScheduler.sharedScheduler forceCheck];
    }
    else {
        // Show the Feeds tab because all possible invalid inputs are currently there
        [self showFeeds:self];
        
        // Shake the window to signal invalid input
        [self.window performShakeAnimation];
        
		//[self showBadURLAlert];
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

- (void)showBadURLAlert {
    // Show an alert warning the user: the feed URL is invalid
    NSAlert *badURLAlert = NSAlert.new;
    badURLAlert.messageText = NSLocalizedString(@"badurl", @"Message for bad feed URL in preferences");
    badURLAlert.alertStyle = NSWarningAlertStyle;
    
    [badURLAlert beginSheetModalForWindow:self.window
                        completionHandler:NULL];
}

@end
