#import "CTCAppDelegate.h"
#import "CTCMainController.h"
#import "CTCDefaults.h"


@interface CTCAppDelegate ()
@property (strong, nonatomic) IBOutlet CTCMainController *mainController;
@end


@implementation CTCAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Create preferences and set default values
	[CTCDefaults setDefaultDefaults];
	
	// Valid config? Check feed, otherwise show Preferences
	if (CTCDefaults.isConfigurationValid) {
        [self.mainController forceCheck];
	}
    else {
        [self.mainController showPreferences:self];
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Save preferences
	[CTCDefaults save];
}

@end
