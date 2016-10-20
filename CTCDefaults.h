#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

extern NSTimeInterval const kCTCDefaultsFeedUpdateInterval;

// Constant, non-localized, non-UI-related strings
extern NSString * const kCTCDefaultsApplicationWebsiteURL;
extern NSString * const kCTCDefaultsApplicationBugReportURL;
extern NSString * const kCTCDefaultsApplicationFeatureRequestURL;
extern NSString * const kCTCDefaultsApplicationHelpURL;
extern NSString * const kCTCDefaultsServiceURL;
extern NSString * const kCTCDefaultsServiceFeedURLRegex;


@interface CTCDefaults : NSObject

+ (void)save;

+ (void)refreshLoginItemStatus;

+ (BOOL)isConfigurationValid;
+ (BOOL)isFeedURLValid;
+ (BOOL)isTorrentsSavePathValid;

+ (NSString *)appName;

+ (NSString *)appVersion;

+ (NSString *)buildNumber;

+ (NSString *)feedURL;

+ (BOOL)areTimeRestrictionsEnabled;

+ (NSDate *)fromDateForTimeRestrictions;

+ (NSDate *)toDateForTimeRestrictions;

+ (BOOL)shouldOrganizeTorrentsInFolders;

+ (BOOL)shouldOpenTorrentsAutomatically;

+ (NSString *)torrentsSavePath;

+ (NSArray<NSDictionary *> *)downloadHistory;

+ (void)setDownloadHistory:(NSArray<NSDictionary *> *)downloadHistory;

+ (BOOL)shouldRunHeadless;

+ (BOOL)shouldPreventSystemSleep;

@end

NS_ASSUME_NONNULL_END
