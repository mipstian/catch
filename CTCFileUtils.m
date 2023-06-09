#import "CTCFileUtils.h"


static NSString * const kCTCFileUtilsTorrentExtension = @".torrent";


@implementation CTCFileUtils

+ (NSData *)bookmarkForURL:(NSURL *)url
                     error:(NSError * __autoreleasing *)outError {
    // Create a bookmark so we can transfer access to the downloads path
    // to the feed checker service
    NSError *error = nil;
    NSData *downloadFolderBookmark = [url bookmarkDataWithOptions:NSURLBookmarkCreationMinimalBookmark
                                                 includingResourceValuesForKeys:@[]
                                                                  relativeToURL:nil
                                                                          error:&error];
    if (!downloadFolderBookmark || error) {
        *outError = error;
        return nil;
    }
    
    return downloadFolderBookmark;
}

+ (NSURL *)URLFromBookmark:(NSData *)bookmark
                     error:(NSError * __autoreleasing *)outError {
    NSError *error = nil;
    BOOL isStale = NO;
    NSURL *URL = [NSURL URLByResolvingBookmarkData:bookmark
                                           options:kNilOptions
                                     relativeToURL:nil
                               bookmarkDataIsStale:&isStale
                                             error:&error];
    
    if (!URL || error) {
        NSLog(@"Could not get URL from bookmark: %@", error);
        *outError = error;
        return nil;
    }
    
    return URL;
}

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
