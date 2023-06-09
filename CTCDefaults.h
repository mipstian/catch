#import <Foundation/Foundation.h>


extern NSTimeInterval const kCTCDefaultsFeedUpdateInterval;

// Constant, non-localized, non-UI-related strings
extern NSString * const kCTCDefaultsApplicationWebsiteURL;
extern NSString * const kCTCDefaultsApplicationBugReportURL;
extern NSString * const kCTCDefaultsApplicationFeatureRequestURL;
extern NSString * const kCTCDefaultsApplicationHelpURL;
extern NSString * const kCTCDefaultsServiceURL;
extern NSString * const kCTCDefaultsServiceFeedURLPrefix;
extern NSString * const kCTCDefaultsLegacyServiceFeedURLPrefix;

extern NSString * const PREFERENCE_KEY_SAVE_PATH;
extern NSString * const PREFERENCE_KEY_ORGANIZE_TORRENTS;
extern NSString * const PREFERENCE_KEY_OPEN_AUTOMATICALLY;
extern NSString * const PREFERENCE_KEY_SEND_NOTIFICATIONS;
extern NSString * const PREFERENCE_KEY_DOWNLOADED_FILES; //Deprecated
extern NSString * const PREFERENCE_KEY_HISTORY;
extern NSString * const PREFERENCE_KEY_OPEN_AT_LOGIN;


@interface CTCDefaults : NSObject

+ (void)setDefaultDefaults;

+ (void)save;

+ (void)refreshLoginItemStatus;

+ (BOOL)isConfigurationValid;

+ (NSString *)appName;

+ (NSString *)appVersion;

+ (NSString *)feedURL;

+ (BOOL)areTimeRestrictionsEnabled;

+ (NSDate *)fromDateForTimeRestrictions;

+ (NSDate *)toDateForTimeRestrictions;

@end
