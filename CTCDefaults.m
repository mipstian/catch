#import "CTCDefaults.h"
#import "CTCLoginItems.h"
#import "CTCFileUtils.h"


// Check feed every 10 minutes
NSTimeInterval const kCTCDefaultsFeedUpdateInterval = 60 * 10;

NSString * const kCTCDefaultsApplicationWebsiteURL = @"http://github.com/mipstian/catch";
NSString * const kCTCDefaultsApplicationBugReportURL = @"https://github.com/mipstian/catch/issues/new?labels=bug";
NSString * const kCTCDefaultsApplicationFeatureRequestURL = @"https://github.com/mipstian/catch/issues/new?labels=enhancement";
NSString * const kCTCDefaultsApplicationHelpURL = @"https://github.com/mipstian/catch/wiki/Configuration";
NSString * const kCTCDefaultsServiceURL = @"https://showrss.info/";
NSString * const kCTCDefaultsServiceFeedURLRegex = @"^https?://([^.]+\\.)*showrss.info/(.*)$";

// NSUserDefaults keys
NSString * const kCTCDefaultsFeedURLKey = @"feedURL";
NSString * const kCTCDefaultsOnlyUpdateBetweenKey = @"onlyUpdateBetween";
NSString * const kCTCDefaultsUpdateFromKey = @"updateFrom";
NSString * const kCTCDefaultsUpdateToKey = @"updateTo";
NSString * const kCTCDefaultsTorrentsSavePathKey = @"savePath";
NSString * const kCTCDefaultsShouldOrganizeTorrents = @"organizeTorrents";
NSString * const kCTCDefaultsShouldOpenTorrentsAutomatically = @"openAutomatically";
NSString * const kCTCDefaultsDownloadedFilesKey = @"downloadedFiles"; // Deprecated
NSString * const kCTCDefaultsDownloadHistoryKey = @"history";
NSString * const kCTCDefaultsOpenAtLoginKey = @"openAtLogin";
NSString * const kCTCDefaultsShouldRunHeadless = @"headless";


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
    
    // Set smart default defaults
    NSDictionary *appDefaults = @{kCTCDefaultsFeedURLKey: @"",
                                  kCTCDefaultsOnlyUpdateBetweenKey: @NO,
                                  kCTCDefaultsUpdateFromKey: dateFrom,
                                  kCTCDefaultsUpdateToKey: dateTo,
                                  kCTCDefaultsTorrentsSavePathKey: defaultDownloadsDirectory,
                                  kCTCDefaultsShouldOrganizeTorrents: @NO,
                                  kCTCDefaultsShouldOpenTorrentsAutomatically: @YES,
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
    [NSUserDefaults.standardUserDefaults synchronize];
}

+ (void)refreshLoginItemStatus {
    [CTCLoginItems toggleRegisteredAsLoginItem:[NSUserDefaults.standardUserDefaults boolForKey:kCTCDefaultsOpenAtLoginKey]];
}

+ (BOOL)isFeedURLValid {
    NSString *feedURL = CTCDefaults.feedURL;
    NSRegularExpression *feedURLRegex = [NSRegularExpression regularExpressionWithPattern:kCTCDefaultsServiceFeedURLRegex options:0 error:nil];
    NSTextCheckingResult *feedURLMatches = [feedURLRegex firstMatchInString:feedURL options:0 range:NSMakeRange(0, [feedURL length])];
    if (!feedURLMatches) {
        // The URL should match the prefix regex!
        NSLog(@"Feed URL (%@) does not match Regex (%@)", feedURL, kCTCDefaultsServiceFeedURLRegex);
        return NO;
    }
    if ([feedURL rangeOfString:@"namespaces"].location == NSNotFound) {
        // The URL should have the namespaces parameter set
        NSLog(@"Feed URL does not have namespaces enabled");
        return NO;
    }
    
    return YES;
}

+ (BOOL)isTorrentsSavePathValid {
    NSString *torrentFolder = self.torrentsSavePath;
    
    if (!torrentFolder) return NO;
    
    BOOL isDirectory = NO;
    BOOL fileExists = [NSFileManager.defaultManager fileExistsAtPath:torrentFolder
                                                         isDirectory:&isDirectory];
    if (!fileExists) return NO;
    if (!isDirectory) return NO;
    
    BOOL isDirectoryWritable = [NSFileManager.defaultManager
                                isWritableFileAtPath:torrentFolder];
    if (!isDirectoryWritable) return NO;
    
    return YES;
}

+ (BOOL)isConfigurationValid {
    return self.isTorrentsSavePathValid && self.isFeedURLValid;
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

+ (BOOL)shouldRunHeadless {
    return [NSUserDefaults.standardUserDefaults boolForKey:kCTCDefaultsShouldRunHeadless];
}

@end
