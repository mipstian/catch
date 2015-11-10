#import <Foundation/Foundation.h>


@interface CTCFileUtils : NSObject

+ (NSData *)bookmarkForURL:(NSURL *)url
                     error:(NSError * __autoreleasing *)error;

+ (NSURL *)URLFromBookmark:(NSData *)bookmark
                     error:(NSError * __autoreleasing *)error;

+ (NSString *)computeFilenameFromURL:(NSURL*)fileURL;

+ (NSString *)torrentFilenameFromString:(NSString*)name;

+ (NSString *)userDownloadsDirectory;

+ (NSString *)userHomeDirectory;

+ (NSString *)fileNameFromString:(NSString *)name;

@end
