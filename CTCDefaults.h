#import <Foundation/Foundation.h>


extern NSTimeInterval const kCTCDefaultsFeedUpdateInterval;

extern NSString * const APPLICATION_WEBSITE_URL;
extern NSString * const APPLICATION_BUG_REPORT_URL;
extern NSString * const APPLICATION_FEATURE_REQUEST_URL;
extern NSString * const APPLICATION_HELP_URL;
extern NSString * const SERVICE_URL;
extern NSString * const SERVICE_FEED_URL_PREFIX;
extern NSString * const SERVICE_FEED_LEGACY_URL_PREFIX;


@interface CTCDefaults : NSObject

+ (NSString *)appName;

+ (NSString *)appVersion;

+ (void)refreshLoginItemStatus;

@end
