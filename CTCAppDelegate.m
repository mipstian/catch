#import "CTCAppDelegate.h"
#import "CTCMainController.h"
#import "Preferences.h"


// Constant, non-localized, non-UI-related strings
NSString * const APPLICATION_WEBSITE_URL = @"http://github.com/mipstian/catch";
NSString * const APPLICATION_BUG_REPORT_URL = @"https://github.com/mipstian/catch/issues/new";
NSString * const APPLICATION_FEATURE_REQUEST_URL = @"https://github.com/mipstian/catch/issues/new";
NSString * const APPLICATION_HELP_URL = @"https://github.com/mipstian/catch/wiki/Configuration";
NSString * const SERVICE_URL = @"http://showrss.info/";
NSString * const SERVICE_FEED_URL_PREFIX = @"http://showrss.info/rss.php?";
NSString * const SERVICE_FEED_LEGACY_URL_PREFIX = @"http://showrss.karmorra.info/rss.php?";


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
