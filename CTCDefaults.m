#import "CTCDefaults.h"
#import "CTCLoginItems.h"
#import "Preferences.h"


// Check feed every 10 minutes
NSTimeInterval const kCTCDefaultsFeedUpdateInterval = 60 * 10;

// Constant, non-localized, non-UI-related strings
NSString * const APPLICATION_WEBSITE_URL = @"http://github.com/mipstian/catch";
NSString * const APPLICATION_BUG_REPORT_URL = @"https://github.com/mipstian/catch/issues/new?labels=bug";
NSString * const APPLICATION_FEATURE_REQUEST_URL = @"https://github.com/mipstian/catch/issues/new?labels=enhancement";
NSString * const APPLICATION_HELP_URL = @"https://github.com/mipstian/catch/wiki/Configuration";
NSString * const SERVICE_URL = @"http://showrss.info/";
NSString * const SERVICE_FEED_URL_PREFIX = @"http://showrss.info/rss.php?";
NSString * const SERVICE_FEED_LEGACY_URL_PREFIX = @"http://showrss.karmorra.info/rss.php?";


@implementation CTCDefaults

+ (NSString *)infoStringForKey:(NSString *)key {
    return [NSBundle.mainBundle objectForInfoDictionaryKey:key];
}

+ (NSString *)appName{
    return [self infoStringForKey:@"CFBundleDisplayName"];
}

+ (NSString *)appVersion {
    return [self infoStringForKey:@"CFBundleShortVersionString"];
}

+ (void)refreshLoginItemStatus {
    [CTCLoginItems toggleRegisteredAsLoginItem:[NSUserDefaults.standardUserDefaults boolForKey:PREFERENCE_KEY_OPEN_AT_LOGIN]];
}

@end
