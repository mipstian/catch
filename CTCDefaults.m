#import "CTCDefaults.h"
#import "CTCLoginItems.h"
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
