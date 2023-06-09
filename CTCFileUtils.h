#import <Foundation/Foundation.h>


@interface CTCFileUtils : NSObject

+ (NSData *)bookmarkForURL:(NSURL *)url
                     error:(NSError * __autoreleasing *)error;

+ (NSURL *)URLFromBookmark:(NSData *)bookmark
                     error:(NSError * __autoreleasing *)error;

+ (NSString *)computeFilenameFromURL:(NSURL*)fileURL;

+ (NSString *)addTorrentExtensionTo:(NSString*)filename;

+ (NSString *)userDownloadsDirectory;

+ (NSString *)userHomeDirectory;

+ (NSString *)folderNameForShowWithName:(NSString *)showName;

@end
