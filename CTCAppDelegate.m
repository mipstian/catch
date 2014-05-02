#import "CTCAppDelegate.h"
#import "GUI.h"
#import "CTCLoginItems.h"


// Constant, non-localized, non-UI-related strings
NSString * const APPLICATION_WEBSITE_URL = @"http://github.com/mipstian/catch";
NSString * const APPLICATION_BUG_REPORT_URL = @"https://github.com/mipstian/catch/issues/new";
NSString * const APPLICATION_FEATURE_REQUEST_URL = @"https://github.com/mipstian/catch/issues/new";
NSString * const APPLICATION_HELP_URL = @"https://github.com/mipstian/catch/wiki/Configuration";
NSString * const SERVICE_URL = @"http://showrss.info/";
NSString * const SERVICE_FEED_URL_PREFIX = @"http://showrss.info/rss.php?";
NSString * const SERVICE_FEED_LEGACY_URL_PREFIX = @"http://showrss.karmorra.info/rss.php?";


@interface CTCAppDelegate ()
@property (strong, nonatomic) CTCScheduler *scheduler;
@property (strong, nonatomic) IBOutlet GUI *gui;
@end


@implementation CTCAppDelegate

- (id)init {
	self = [super init];
	if (!self) {
		return nil;
	}
    
    self.scheduler = CTCScheduler.new;

	NSLog(@"Loading preferences");
	
	// Create preferences and set default values
	[Preferences setDefaults];
    // This ensures we have the latest values from the user
	[Preferences save];
	
	// Register as a login item if needed
	[self refreshLoginItemStatus];

	return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	NSLog(@"Catch: finished launching");
	
	// show Preferences folder if the config is not valid
	if (![Preferences validate]) {
		[self.gui showPreferences:self];
	}
	
	// Also check now
	[self.scheduler forceCheck];
}

- (void)schedulerStatusActive:(BOOL)isActive running:(BOOL)isRunning {
	[self.gui setStatusActive:isActive running:isRunning];
}

- (void)lastUpdateStatus:(BOOL)lastUpdateWasSuccessful time:(NSDate*)time {
	[self.gui setLastUpdateStatus:lastUpdateWasSuccessful time:time];
	
	// Also refresh the list of recently downloaded torrents
	// Get the full list
	NSArray *downloaded = [NSUserDefaults.standardUserDefaults arrayForKey:PREFERENCE_KEY_HISTORY];
	// Get last 10 elements
	NSRange recentRange;
	recentRange.length = (downloaded.count > 10) ? 10 : downloaded.count;
	recentRange.location = downloaded.count - recentRange.length;
	
	NSArray *recent = [downloaded subarrayWithRange:recentRange];
	NSArray *cleanRecent = NSArray.array;
	int count = recent.count;
	
	for (int i = 1; i <= count; i++) {
		NSString *clean = [[recent objectAtIndex:count-i] objectForKey:@"title"];
		clean = [[NSString stringWithFormat:@"%d ",i] stringByAppendingString:clean];
		cleanRecent = [cleanRecent arrayByAddingObject:clean];
	}
	
	[self.gui refreshRecent:cleanRecent];
}

- (void)checkNow {
	[self.scheduler forceCheck];
}

- (void)togglePause {
	if ([self.scheduler pauseResume]) {
		// If the scheduler is now active, also force a check right away
		[self.scheduler forceCheck];
	}
}

- (void)savePreferences {
	[Preferences save];
	
	// Register as a login item if needed
	[self refreshLoginItemStatus];
	
	// Also force check
	[self checkNow];
}

- (BOOL)isConfigurationValid {
	return [Preferences validate];
}

- (void)torrentNotificationWithDescription:(NSString *)description {
	[self.gui torrentNotificationWithDescription:description];
}

- (void)orderFrontStandardAboutPanel:(id)sender {
	// Do nothing
}

- (void)refreshLoginItemStatus {
    [CTCLoginItems toggleRegisteredAsLoginItem:[NSUserDefaults.standardUserDefaults boolForKey:PREFERENCE_KEY_OPEN_AT_LOGIN]];
}

- (void)quit {
	NSLog(@"Catch: quitting");
	// Save preferences
	[Preferences save];
	
	NSLog(@"Catch: all done, bye bye");
	// Quit
	[NSApp terminate:nil];
}

@end
