#import "CTCDefaults.h"
#import "CTCLoginItems.h"
#import "CTCFileUtils.h"


// Check feed every 10 minutes
NSTimeInterval const kCTCDefaultsFeedUpdateInterval = 60 * 10;

NSString * const kCTCDefaultsApplicationWebsiteURL = @"http://github.com/mipstian/catch";
NSString * const kCTCDefaultsApplicationBugReportURL = @"https://github.com/mipstian/catch/issues/new?labels=bug";
NSString * const kCTCDefaultsApplicationFeatureRequestURL = @"https://github.com/mipstian/catch/issues/new?labels=enhancement";
NSString * const kCTCDefaultsApplicationHelpURL = @"https://github.com/mipstian/catch/wiki/Configuration";
NSString * const kCTCDefaultsServiceURL = @"http://showrss.info/";
NSString * const kCTCDefaultsServiceFeedURLPrefix = @"http://showrss.info/rss.php?";

// NSUserDefaults keys
NSString * const kCTCDefaultsFeedURLKey = @"feedURL";
NSString * const kCTCDefaultsOnlyUpdateBetweenKey = @"onlyUpdateBetween";
NSString * const kCTCDefaultsUpdateFromKey = @"updateFrom";
NSString * const kCTCDefaultsUpdateToKey = @"updateTo";
NSString * const kCTCDefaultsTorrentsSavePathKey = @"savePath";
NSString * const kCTCDefaultsShouldOrganizeTorrents = @"organizeTorrents";
NSString * const kCTCDefaultsShouldOpenTorrentsAutomatically = @"openAutomatically";
NSString * const kCTCDefaultsShouldSendNotificationsKey = @"growlNotifications";
NSString * const kCTCDefaultsDownloadedFilesKey = @"downloadedFiles"; // Deprecated
NSString * const kCTCDefaultsDownloadHistoryKey = @"history";
NSString * const kCTCDefaultsOpenAtLoginKey = @"openAtLogin";


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
	
	// Use user's Downloads directory as a default, fallback on home
	NSString *defaultDownloadsDirectory = CTCFileUtils.userDownloadsDirectory ?: CTCFileUtils.userHomeDirectory;
    NSLog(@"Default downloads directory is %@", defaultDownloadsDirectory);
	
	// Set smart defaults for the preferences
	NSDictionary *appDefaults = @{kCTCDefaultsFeedURLKey: @"",
                                  kCTCDefaultsOnlyUpdateBetweenKey: @NO,
                                  kCTCDefaultsUpdateFromKey: dateFrom,
                                  kCTCDefaultsUpdateToKey: dateTo,
                                  kCTCDefaultsTorrentsSavePathKey: defaultDownloadsDirectory,
                                  kCTCDefaultsShouldOrganizeTorrents: @NO,
                                  kCTCDefaultsShouldOpenTorrentsAutomatically: @YES,
                                  kCTCDefaultsShouldSendNotificationsKey: @YES,
                                  kCTCDefaultsOpenAtLoginKey: @YES};
	[NSUserDefaults.standardUserDefaults registerDefaults:appDefaults];
    
	// Migrate the downloads history format. Change old array of strings to new dictionary format
	NSArray *downloadedFiles = [NSUserDefaults.standardUserDefaults arrayForKey:kCTCDefaultsDownloadedFilesKey];
	NSArray *history = self.downloadHistory;
	if (downloadedFiles && !history) {
		NSLog(@"Migrating download history to new format.");
		
		NSMutableArray *newDownloadedFiles = NSMutableArray.array;
		
		for (NSString *url in downloadedFiles) {
            NSString *fileName = [CTCFileUtils computeFilenameFromURL:[NSURL URLWithString:url]];
			[newDownloadedFiles addObject:@{@"title": fileName,
                                            @"url": url}];
		}
		
        self.downloadHistory = newDownloadedFiles;
		[NSUserDefaults.standardUserDefaults removeObjectForKey:kCTCDefaultsDownloadedFilesKey];
	}
    
    // If history was never set or migrated, init it to empty array
    if (!downloadedFiles && !history) {
        self.downloadHistory = @[];
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
    [CTCLoginItems toggleRegisteredAsLoginItem:[NSUserDefaults.standardUserDefaults boolForKey:kCTCDefaultsOpenAtLoginKey]];
}

+ (BOOL)isConfigurationValid {
	// Validate torrent folder. This should never fail!
	NSString *torrentFolder = self.torrentsSavePath;
	
	if (!torrentFolder) return NO;
    
	BOOL isDirectory = NO;
	if ([NSFileManager.defaultManager fileExistsAtPath:torrentFolder
                                           isDirectory:&isDirectory]) {
		if (!isDirectory) return NO;
	}
    else {
		return NO;
	}
    
	// Most importantly, validate feed URL
	NSString *feedURL = CTCDefaults.feedURL;
	NSRange range = [feedURL rangeOfString:kCTCDefaultsServiceFeedURLPrefix];
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
	NSString *rawFeedURL = [NSUserDefaults.standardUserDefaults stringForKey:kCTCDefaultsFeedURLKey];
	return rawFeedURL ? [rawFeedURL stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] : @"";
}

+ (BOOL)areTimeRestrictionsEnabled {
    return [NSUserDefaults.standardUserDefaults boolForKey:kCTCDefaultsOnlyUpdateBetweenKey];
}

+ (NSDate *)fromDateForTimeRestrictions {
    return (NSDate *)[NSUserDefaults.standardUserDefaults objectForKey:kCTCDefaultsUpdateFromKey];
}

+ (NSDate *)toDateForTimeRestrictions {
    return (NSDate *)[NSUserDefaults.standardUserDefaults objectForKey:kCTCDefaultsUpdateToKey];
}

+ (BOOL)shouldSendNotifications {
    return [NSUserDefaults.standardUserDefaults boolForKey:kCTCDefaultsShouldSendNotificationsKey];
}

+ (BOOL)shouldOrganizeTorrentsInFolders {
    return [NSUserDefaults.standardUserDefaults boolForKey:kCTCDefaultsShouldOrganizeTorrents];
}

+ (BOOL)shouldOpenTorrentsAutomatically {
    return [NSUserDefaults.standardUserDefaults boolForKey:kCTCDefaultsShouldOpenTorrentsAutomatically];
}

+ (NSString *)torrentsSavePath {
    return [NSUserDefaults.standardUserDefaults stringForKey:kCTCDefaultsTorrentsSavePathKey].stringByStandardizingPath;
}

+ (NSArray *)downloadHistory {
    return [NSUserDefaults.standardUserDefaults arrayForKey:kCTCDefaultsDownloadHistoryKey];
}

+ (void)setDownloadHistory:(NSArray *)downloadHistory {
    [NSUserDefaults.standardUserDefaults setObject:downloadHistory
                                            forKey:kCTCDefaultsDownloadHistoryKey];
}

@end
