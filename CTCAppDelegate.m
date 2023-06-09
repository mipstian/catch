#import "CTCAppDelegate.h"
#import "CTCMenuController.h"
#import "CTCPreferencesController.h"
#import "CTCDefaults.h"
#import "CTCScheduler.h"


@implementation CTCAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Set default values for defaults
	[CTCDefaults setDefaultDefaults];
    
	// Enable Notification Center notifications
    [NSUserNotificationCenter.defaultUserNotificationCenter setDelegate:self];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Save defaults
	[CTCDefaults save];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
	 shouldPresentNotification:(NSUserNotification *)notification {
	return YES;
}

@end
