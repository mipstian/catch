#import "CTCAppDelegate.h"
#import "CTCMainController.h"
#import "Preferences.h"


@interface CTCAppDelegate ()
@property (strong, nonatomic) IBOutlet CTCMainController *mainController;
@end


@implementation CTCAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Create preferences and set default values
	[Preferences setDefaultDefaults];
	
	// Valid config? Check feed, otherwise show Preferences
	if (Preferences.isConfigurationValid) {
        [self.mainController forceCheck];
	}
    else {
        [self.mainController showPreferences:self];
    }
}

@end
