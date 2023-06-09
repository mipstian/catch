#import "CTCDefaults.h"


// Check feed every 10 minutes
NSTimeInterval const kCTCDefaultsFeedUpdateInterval = 60 * 10;


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

@end
