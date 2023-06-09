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

+ (BOOL)shouldSendNotifications;

+ (BOOL)shouldOrganizeTorrentsInFolders;

+ (BOOL)shouldOpenTorrentsAutomatically;

+ (NSString *)torrentsSavePath;

+ (NSArray *)downloadHistory;

+ (void)setDownloadHistory:(NSArray *)downloadHistory;

@end
