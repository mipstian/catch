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
	
	// Show Preferences window if the config is not valid
	if (!Preferences.isConfigurationValid) {
		[self.mainController showPreferences:self];
	}
	
	// Also check now
    [self.mainController forceCheck];
}

- (void)schedulerStatusActive:(BOOL)isActive running:(BOOL)isRunning {
	[self.mainController setStatusActive:isActive running:isRunning];
}

- (void)lastUpdateStatus:(BOOL)lastUpdateWasSuccessful time:(NSDate*)time {
	[self.mainController setLastUpdateStatus:lastUpdateWasSuccessful time:time];
	
	// Also refresh the list of recently downloaded torrents
	// Get the full list
	NSArray *downloaded = [NSUserDefaults.standardUserDefaults arrayForKey:PREFERENCE_KEY_HISTORY];
    
	// Get last 10 elements
	NSRange recentRange;
	recentRange.length = (downloaded.count > 10) ? 10 : downloaded.count;
	recentRange.location = downloaded.count - recentRange.length;
	NSArray *recents = [downloaded subarrayWithRange:recentRange];
    
    // Extract titles
    NSMutableArray *recentNames = NSMutableArray.array;
    for (NSDictionary *recentItem in recents) {
        [recentNames addObject:recentItem[@"title"]];
    }
	
	[self.mainController refreshRecent:recentNames];
}

@end
