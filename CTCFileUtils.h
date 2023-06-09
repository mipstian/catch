#import <Foundation/Foundation.h>


@interface CTCFileUtils : NSObject

+ (NSString*)computeFilenameFromURL:(NSURL*)fileURL;

+ (NSString*)addTorrentExtensionTo:(NSString*)filename;

@end
