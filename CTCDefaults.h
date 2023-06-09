#import <Foundation/Foundation.h>


extern NSTimeInterval const kCTCDefaultsFeedUpdateInterval;


@interface CTCDefaults : NSObject

+ (NSString *)appName;

+ (NSString *)appVersion;

@end
