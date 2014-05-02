#import <Cocoa/Cocoa.h>


// NSUserDefaults keys
extern NSString * const PREFERENCE_KEY_FEED_URL;
extern NSString * const PREFERENCE_KEY_ONLY_UPDATE_BETWEEN;
extern NSString * const PREFERENCE_KEY_UPDATE_FROM;
extern NSString * const PREFERENCE_KEY_UPDATE_TO;
extern NSString * const PREFERENCE_KEY_SAVE_PATH;
extern NSString * const PREFERENCE_KEY_ORGANIZE_TORRENTS;
extern NSString * const PREFERENCE_KEY_OPEN_AUTOMATICALLY;
extern NSString * const PREFERENCE_KEY_SEND_NOTIFICATIONS;
extern NSString * const PREFERENCE_KEY_DOWNLOADED_FILES; //Deprecated
extern NSString * const PREFERENCE_KEY_HISTORY;
extern NSString * const PREFERENCE_KEY_OPEN_AT_LOGIN;


@interface Preferences : NSObject

+ (void)setDefaultDefaults;
+ (void)save;
+ (BOOL)validate;
+ (NSString *)feedURL;

@end
