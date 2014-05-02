#import "Preferences.h"
#import "CTCDefaults.h"


NSString * const PREFERENCE_KEY_FEED_URL = @"feedURL";
NSString * const PREFERENCE_KEY_ONLY_UPDATE_BETWEEN = @"onlyUpdateBetween";
NSString * const PREFERENCE_KEY_UPDATE_FROM = @"updateFrom";
NSString * const PREFERENCE_KEY_UPDATE_TO = @"updateTo";
NSString * const PREFERENCE_KEY_SAVE_PATH = @"savePath";
NSString * const PREFERENCE_KEY_ORGANIZE_TORRENTS = @"organizeTorrents";
NSString * const PREFERENCE_KEY_OPEN_AUTOMATICALLY = @"openAutomatically";
NSString * const PREFERENCE_KEY_SEND_NOTIFICATIONS = @"growlNotifications";
NSString * const PREFERENCE_KEY_DOWNLOADED_FILES = @"downloadedFiles";
NSString * const PREFERENCE_KEY_HISTORY = @"history";
NSString * const PREFERENCE_KEY_OPEN_AT_LOGIN = @"openAtLogin";


@implementation Preferences

+ (BOOL)isConfigurationValid {
	// Validate torrent folder. This should never fail!
	NSString *torrentFolder = [NSUserDefaults.standardUserDefaults stringForKey:PREFERENCE_KEY_SAVE_PATH];
	torrentFolder = [torrentFolder stringByStandardizingPath];
	
	if (!torrentFolder) return NO;

	BOOL isDirectory = NO;
	if ([NSFileManager.defaultManager fileExistsAtPath:torrentFolder
                                           isDirectory:&isDirectory]) {
		if (!isDirectory) return NO;
	} else {
		return NO;
	}

	// Most importantly, validate feed URL
	NSString *feedURL = CTCDefaults.feedURL;
	NSRange range = [feedURL rangeOfString:kCTCDefaultsServiceFeedURLPrefix];
	if (range.location != 0) {
		// Try the legacy URL prefix and consider that valid
		range = [feedURL rangeOfString:kCTCDefaultsLegacyServiceFeedURLPrefix];
	}
	if (range.location != 0) {
		// The URL should start with the prefix!
		NSLog(@"Feed URL does not start with expected prefix. Range of expected prefix: %lu %lu", (unsigned long)range.location, (unsigned long)range.length);
		return NO;
	}
	range = [feedURL rangeOfString:@"namespaces"];
	if (range.location == NSNotFound) {
		// The URL should have the namespaces parameter set
		NSLog(@"Feed URL does not have namespaces enabled");
		return NO;
	}
	
	return YES;
}

@end
