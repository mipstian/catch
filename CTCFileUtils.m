#import "CTCFileUtils.h"


static NSString * const kCTCFileUtilsTorrentExtension = @".torrent";


@implementation CTCFileUtils

+ (NSString *)computeFilenameFromURL:(NSURL*)fileURL {
	// Compute destination filename
	NSString *filename = fileURL.path.pathComponents.lastObject;
    
    // Reverse urlencode
	return [filename stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

+ (NSString *)addTorrentExtensionTo:(NSString*)filename {
	NSRange range = [filename rangeOfString:kCTCFileUtilsTorrentExtension];
    
    // Extension is missing if not found or if found but not at the end of the filename
    BOOL extensionMissing = range.location == NSNotFound || range.location + range.length != filename.length;
    
    // Add .torrent extension if needed
    return extensionMissing ? [filename stringByAppendingString:kCTCFileUtilsTorrentExtension] : filename;
}

+ (NSString *)userDownloadsDirectory {
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES);
    
    // Might be nil!
    return searchPaths.firstObject;
}

+ (NSString *)userHomeDirectory {
    return NSHomeDirectory();
}

@end
