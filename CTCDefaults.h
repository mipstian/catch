#import <Foundation/Foundation.h>


extern NSTimeInterval const kCTCDefaultsFeedUpdateInterval;

extern NSString * const kCTCDefaultsApplicationWebsiteURL;
extern NSString * const kCTCDefaultsApplicationBugReportURL;
extern NSString * const kCTCDefaultsApplicationFeatureRequestURL;
extern NSString * const kCTCDefaultsApplicationHelpURL;

extern NSString * const kCTCDefaultsServiceURL;
extern NSString * const kCTCDefaultsServiceFeedURLPrefix;
extern NSString * const kCTCDefaultsLegacyServiceFeedURLPrefix;


@interface CTCDefaults : NSObject

+ (NSString *)appName;

+ (NSString *)appVersion;

+ (void)refreshLoginItemStatus;

@end
