#import "CTCAppDelegate.h"
#import "CTCMenuController.h"
#import "CTCPreferencesController.h"
#import "CTCDefaults.h"
#import "CTCScheduler.h"


@implementation CTCAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Set default values for defaults
	[CTCDefaults setDefaultDefaults];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Save defaults
	[CTCDefaults save];
}

@end
