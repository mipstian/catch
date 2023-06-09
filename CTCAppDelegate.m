#import "CTCAppDelegate.h"
#import "CTCMenuController.h"
#import "CTCPreferencesController.h"
#import "CTCDefaults.h"
#import "CTCScheduler.h"


@implementation CTCAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Create preferences and set default values
	[CTCDefaults setDefaultDefaults];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Save preferences
	[CTCDefaults save];
}

@end
