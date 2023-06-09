#import "CTCDefaults.h"
#import "CTCLoginItems.h"
#import "CTCFileUtils.h"
#import "Preferences.h"


// Check feed every 10 minutes
NSTimeInterval const kCTCDefaultsFeedUpdateInterval = 60 * 10;

// Constant, non-localized, non-UI-related strings
NSString * const kCTCDefaultsApplicationWebsiteURL = @"http://github.com/mipstian/catch";
NSString * const kCTCDefaultsApplicationBugReportURL = @"https://github.com/mipstian/catch/issues/new?labels=bug";
NSString * const kCTCDefaultsApplicationFeatureRequestURL = @"https://github.com/mipstian/catch/issues/new?labels=enhancement";
NSString * const kCTCDefaultsApplicationHelpURL = @"https://github.com/mipstian/catch/wiki/Configuration";

NSString * const kCTCDefaultsServiceURL = @"http://showrss.info/";
NSString * const kCTCDefaultsServiceFeedURLPrefix = @"http://showrss.info/rss.php?";
NSString * const kCTCDefaultsLegacyServiceFeedURLPrefix = @"http://showrss.karmorra.info/rss.php?";


@implementation CTCDefaults

+ (void)setDefaultDefaults {
	// Create two dummy times (dates actually), just to have some value set
	NSDateComponents *comps = NSDateComponents.new;
    comps.hour = 24;
    comps.minute = 0;
	NSCalendar *calendar = NSCalendar.currentCalendar;
	NSDate *dateFrom = [calendar dateFromComponents:comps];
    comps.hour = 8;
	NSDate *dateTo = [calendar dateFromComponents:comps];
	
	// Search for user's Downloads directory (by the book)
	NSString *downloadsDirectory;
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES);
	if (paths.count > 0) {
		downloadsDirectory = paths.firstObject;
		NSLog(@"Default save path is %@", downloadsDirectory);
	} else {
		// Default to ~/Downloads/ (at this point it probably won't work though)
		NSLog(@"Defaulting to ~/Downloads/ for save path");
		downloadsDirectory = @"~/Downloads/";
	}
	
	// Set smart defaults for the preferences
	NSDictionary *appDefaults = @{PREFERENCE_KEY_FEED_URL: @"",
                                  PREFERENCE_KEY_ONLY_UPDATE_BETWEEN: @NO,
                                  PREFERENCE_KEY_UPDATE_FROM: dateFrom,
                                  PREFERENCE_KEY_UPDATE_TO: dateTo,
                                  PREFERENCE_KEY_SAVE_PATH: downloadsDirectory,
                                  PREFERENCE_KEY_ORGANIZE_TORRENTS: @NO,
                                  PREFERENCE_KEY_OPEN_AUTOMATICALLY: @YES,
                                  PREFERENCE_KEY_SEND_NOTIFICATIONS: @YES,
                                  PREFERENCE_KEY_OPEN_AT_LOGIN: @YES};
	[NSUserDefaults.standardUserDefaults registerDefaults:appDefaults];
    
	// Migrate the downloads history format. Change old array of strings to new dictionary format
	NSArray *downloadedFiles = [NSUserDefaults.standardUserDefaults arrayForKey:PREFERENCE_KEY_DOWNLOADED_FILES];
	NSArray *history = [NSUserDefaults.standardUserDefaults arrayForKey:PREFERENCE_KEY_HISTORY];
	if (downloadedFiles && !history) {
		NSLog(@"Migrating download history to new format.");
		
		NSMutableArray *newDownloadedFiles = NSMutableArray.array;
		
		for (NSString *url in downloadedFiles) {
			[newDownloadedFiles addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                           [CTCFileUtils computeFilenameFromURL:[NSURL URLWithString:url]], @"title",
                                           url, @"url",
                                           nil]];
		}
		
		[NSUserDefaults.standardUserDefaults setObject:newDownloadedFiles
                                                forKey:PREFERENCE_KEY_HISTORY];
		[NSUserDefaults.standardUserDefaults removeObjectForKey:PREFERENCE_KEY_DOWNLOADED_FILES];
	}
    
    // If history was never set or migrated, init it to empty array
    if (!downloadedFiles && !history) {
        [NSUserDefaults.standardUserDefaults setObject:@[]
                                                forKey:PREFERENCE_KEY_HISTORY];
    }
    
    // Register as a login item if needed
    [self refreshLoginItemStatus];
}

+ (void)save {
	// Write preferences to disk
	[NSUserDefaults.standardUserDefaults synchronize];
    
    // Register as a login item if needed
    [self refreshLoginItemStatus];
}

+ (void)refreshLoginItemStatus {
    [CTCLoginItems toggleRegisteredAsLoginItem:[NSUserDefaults.standardUserDefaults boolForKey:PREFERENCE_KEY_OPEN_AT_LOGIN]];
}

+ (NSString *)infoStringForKey:(NSString *)key {
    return [NSBundle.mainBundle objectForInfoDictionaryKey:key];
}

+ (NSString *)appName{
    return [self infoStringForKey:@"CFBundleDisplayName"];
}

+ (NSString *)appVersion {
    return [self infoStringForKey:@"CFBundleShortVersionString"];
}

+ (NSString *)feedURL {
	NSString *rawFeedURL = [NSUserDefaults.standardUserDefaults stringForKey:PREFERENCE_KEY_FEED_URL];
	return [rawFeedURL stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
}

@end
