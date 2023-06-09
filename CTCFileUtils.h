#import <Foundation/Foundation.h>


@interface CTCFileUtils : NSObject

+ (NSString *)computeFilenameFromURL:(NSURL*)fileURL;

+ (NSString *)addTorrentExtensionTo:(NSString*)filename;

+ (NSString *)userDownloadsDirectory;

+ (NSString *)userHomeDirectory;

+ (NSString *)folderNameForShowWithName:(NSString *)showName;

@end
