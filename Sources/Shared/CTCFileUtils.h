#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CTCFileUtils : NSObject

+ (NSData * __nullable)bookmarkForURL:(NSURL *)url
                     error:(NSError * __nullable __autoreleasing *)error;

+ (NSURL *)URLFromBookmark:(NSData *)bookmark
                     error:(NSError * __nullable __autoreleasing *)error;

+ (NSString *)filenameFromURL:(NSURL*)fileURL;

+ (NSString *)torrentFilenameFromString:(NSString*)name;
+ (NSString *)magnetFilenameFromString:(NSString *)name;

+ (NSString * __nullable)userDownloadsDirectory;

+ (NSString *)userHomeDirectory;

+ (NSString *)fileNameFromString:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
