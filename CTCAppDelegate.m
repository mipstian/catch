#import "CTCAppDelegate.h"
#import "CTCMenuController.h"
#import "CTCPreferencesController.h"
#import "CTCDefaults.h"
#import "CTCScheduler.h"


@interface CTCAppDelegate ()
@property (strong, nonatomic) IBOutlet CTCPreferencesController *preferencesController;
@end


@implementation CTCAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Create preferences and set default values
	[CTCDefaults setDefaultDefaults];
	
	// Valid config? Check feed right now
	if (CTCDefaults.isConfigurationValid) [CTCScheduler.sharedScheduler forceCheck];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Save preferences
	[CTCDefaults save];
}

@end
