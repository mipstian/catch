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

+ (void)setDefaultDefaults;

+ (void)save;

+ (void)refreshLoginItemStatus;

+ (NSString *)appName;

+ (NSString *)appVersion;

+ (NSString *)feedURL;

@end
