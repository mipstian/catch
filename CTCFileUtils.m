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
    BOOL hasExtension = [filename hasSuffix:kCTCFileUtilsTorrentExtension];
    
    // Add .torrent extension if needed
    return hasExtension ? filename : [filename stringByAppendingString:kCTCFileUtilsTorrentExtension];
}

+ (NSString *)userDownloadsDirectory {
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES);
    
    // Might be nil!
    return searchPaths.firstObject;
}

+ (NSString *)userHomeDirectory {
    return NSHomeDirectory();
}

+ (NSString *)folderNameForShowWithName:(NSString *)showName {
    return [[showName stringByReplacingOccurrencesOfString:@"/" withString:@""] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
}

@end
