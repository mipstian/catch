#import "CTCFileUtils.h"


static NSString * const kCTCFileUtilsTorrentExtension = @".torrent";
static NSString * const kCTCFileUtilsWeblocExtension = @".webloc";


@implementation CTCFileUtils

+ (NSData *)bookmarkForURL:(NSURL *)url
                     error:(NSError * __autoreleasing *)outError {
    NSError *error = nil;
    NSData *bookmark = [url bookmarkDataWithOptions:NSURLBookmarkCreationMinimalBookmark
                                                 includingResourceValuesForKeys:@[]
                                                                  relativeToURL:nil
                                                                          error:&error];
    if (!bookmark || error) {
        *outError = error;
        return nil;
    }
    
    return bookmark;
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

+ (NSString *)filenameFromURL:(NSURL *)fileURL {
    // Compute destination filename
    NSString *filename = fileURL.path.pathComponents.lastObject;
    
    // Reverse urlencode
    return [filename stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

+ (NSString *)filenameFromString:(NSString *)name withExtension:(NSString *)extension {
    NSString *cleanName = [self fileNameFromString:name];
    
    BOOL hasExtension = [cleanName hasSuffix:extension];
    
    // Add extension if needed
    return hasExtension ? cleanName : [cleanName stringByAppendingString:extension];
}

+ (NSString *)torrentFilenameFromString:(NSString *)name {
    return [self filenameFromString:name withExtension:kCTCFileUtilsTorrentExtension];
}

+ (NSString *)magnetFilenameFromString:(NSString *)name {
    return [self filenameFromString:name withExtension:kCTCFileUtilsWeblocExtension];
}

+ (NSString *)userDownloadsDirectory {
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES);
    
    // Might be nil!
    return searchPaths.firstObject;
}

+ (NSString *)userHomeDirectory {
    return NSHomeDirectory();
}

+ (NSString *)fileNameFromString:(NSString *)name {
    return [[name stringByReplacingOccurrencesOfString:@"/" withString:@""] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
}

@end
