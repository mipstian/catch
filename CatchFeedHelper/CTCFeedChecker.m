#import "CTCFeedChecker.h"
#import "CTCFeedParser.h"
#import "CTCFileUtils.h"


NSString *kCTCFeedCheckerErrorDomain = @"com.giorgiocalderolla.Catch.CatchFeedHelper";


@implementation CTCFeedChecker

+ (instancetype)sharedChecker {
    static CTCFeedChecker *sharedChecker = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedChecker = CTCFeedChecker.new;
    });
    
    return sharedChecker;
}

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(CTCFeedCheck)];
    newConnection.exportedObject = self;
    [newConnection resume];
    
    return YES;
}

- (void)checkShowRSSFeed:(NSURL *)feedURL
   downloadingToBookmark:(NSData *)downloadFolderBookmark
      organizingByFolder:(BOOL)shouldOrganizeByFolder
            skippingURLs:(NSArray *)previouslyDownloadedURLs
               withReply:(CTCFeedCheckCompletionHandler)reply {
    NSLog(@"Checking feed");
    
    NSError *error = nil;
    
    // Resolve the bookmark (that the main app gives us to transfer access to
    // the download folder) to a URL
    NSURL *downloadFolderURL = [CTCFileUtils URLFromBookmark:downloadFolderBookmark
                                                       error:&error];
    if (!downloadFolderURL) {
        reply(@[], error);
        return;
    }
    
    NSString *downloadFolderPath = downloadFolderURL.path;
    
    // Download the feed
    NSXMLDocument *feed = [self downloadFeed:feedURL error:&error];
    if (!feed) {
        reply(@[], [NSError errorWithDomain:kCTCFeedCheckerErrorDomain
                                       code:-5
                                   userInfo:@{NSLocalizedDescriptionKey: @"Could not download feed",
                                              NSUnderlyingErrorKey: error}]);
        return;
    }
    
    // Parse the feed for files
    NSArray *feedFiles = [CTCFeedParser parseFiles:feed error:&error];
    if (!feedFiles) {
        reply(@[], [NSError errorWithDomain:kCTCFeedCheckerErrorDomain
                                       code:-6
                                   userInfo:@{NSLocalizedDescriptionKey: @"Could not parse feed",
                                              NSUnderlyingErrorKey: error}]);
        return;
    }
    
    // Download the files
    NSArray *downloadedFeedFiles = [self downloadFiles:feedFiles
                                                toPath:downloadFolderPath
                                    organizingByFolder:shouldOrganizeByFolder
                                          skippingURLs:previouslyDownloadedURLs
                                                 error:&error];
    
    NSLog(@"All done");
    
    reply(downloadedFeedFiles, error);
}

- (void)downloadFile:(NSDictionary *)file
          toBookmark:(NSData *)downloadFolderBookmark
  organizingByFolder:(BOOL)shouldOrganizeByFolder
           withReply:(CTCFeedCheckDownloadCompletionHandler)reply {
    NSLog(@"Downloading single file");
    
    NSError *error = nil;
    
    // Resolve the bookmark (that the main app gives us to transfer access to
    // the download folder) to a URL
    NSURL *downloadFolderURL = [CTCFileUtils URLFromBookmark:downloadFolderBookmark
                                                       error:&error];
    if (!downloadFolderURL) {
        reply(nil, error);
        return;
    }
    
    NSString *downloadFolderPath = downloadFolderURL.path;
    
    // Download the file
    NSArray *downloadedFiles = [self downloadFiles:@[file]
                 toPath:downloadFolderPath
     organizingByFolder:shouldOrganizeByFolder
           skippingURLs:@[]
                  error:&error];
    
    NSLog(@"All done");
    
    reply(downloadedFiles.firstObject, error);
}

- (NSXMLDocument*)downloadFeed:(NSURL*)feedURL
                         error:(NSError * __autoreleasing *)outError {
    NSLog(@"Downloading feed %@", feedURL);
    
    // Flush the cache, we want fresh results
    [NSURLCache.sharedURLCache removeAllCachedResponses];
    
    NSError *error = nil;
    
    // Create a NSXMLDocument by downloading feed
    NSXMLDocument *document = [[NSXMLDocument alloc] initWithContentsOfURL:feedURL
                                                                   options:NSXMLNodeOptionsNone
                                                                     error:&error];
    
    if (!document) {
        *outError = error;
        return nil;
    }
    
    NSLog(@"Feed downloaded");
    
    return document;
}

- (NSArray *)downloadFiles:(NSArray *)feedFiles
                    toPath:(NSString *)downloadPath
        organizingByFolder:(BOOL)shouldOrganizeByFolder
              skippingURLs:(NSArray *)previouslyDownloadedURLs
                     error:(NSError * __autoreleasing *)outError {
    NSError *error = nil;
    
    NSLog(@"Downloading files (if needed)");
    
    NSMutableArray *successfullyDownloadedFeedFiles = NSMutableArray.array;
    
    for (NSDictionary *file in feedFiles) {
        NSString *url = file[@"url"];
        
        // Skip old files
        if ([previouslyDownloadedURLs containsObject:url]) continue;
        
        BOOL isMagnetLink = [url rangeOfString:@"magnet:"].location == 0;
        
        // The file is new, open magnet or download torrent
        if (isMagnetLink) {
            [successfullyDownloadedFeedFiles addObject:@{@"url": file[@"url"],
                                                         @"title": file[@"title"],
                                                         @"isMagnetLink": @YES}];
        }
        else {
            // First get the folder, if we want it and it's available
            NSString *showName = shouldOrganizeByFolder && ![file[@"showName"] isEqualTo:NSNull.null] ? file[@"showName"] : nil;
            
            NSString *downloadedTorrentFile = [self downloadFile:file
                                                          toPath:downloadPath
                                                    withShowName:showName
                                                           error:&error];
            if (downloadedTorrentFile) {
                [successfullyDownloadedFeedFiles addObject:@{@"url": url,
                                                             @"title": file[@"title"],
                                                             @"isMagnetLink": @NO,
                                                             @"torrentFilePath": downloadedTorrentFile}];
            }
            else {
                NSLog(@"Could not download %@: %@", url, error);
                *outError = error;
            }
        }
    }
    
    return successfullyDownloadedFeedFiles.copy;
}

- (NSString *)downloadFile:(NSDictionary *)file
                    toPath:(NSString *)downloadPath
              withShowName:(NSString *)showName
                     error:(NSError * __autoreleasing *)outError {
    NSString *folder = [CTCFileUtils fileNameFromString:showName];
    
    if (folder) NSLog(@"Downloading file to folder %@", folder);
    else NSLog(@"Downloading file");
    
    NSError *error = nil;

    NSURL *fileURL = [NSURL URLWithString:file[@"url"]];
    
    // Download!
    NSURLRequest *urlRequest = [[NSURLRequest alloc] initWithURL:fileURL];
    NSHTTPURLResponse *urlResponse = NSHTTPURLResponse.new;
    NSData *downloadedFile = [NSURLConnection sendSynchronousRequest:urlRequest
                                           returningResponse:&urlResponse
                                                       error:&error];
    
    if (!downloadedFile) {
        *outError = [NSError errorWithDomain:kCTCFeedCheckerErrorDomain
                                        code:-1
                                    userInfo:@{NSLocalizedDescriptionKey: @"Could not download file",
                                               NSUnderlyingErrorKey: error}];
        return nil;
    }
    
    if (urlResponse.statusCode != 200) {
        NSString *errorDescription = [NSString stringWithFormat:@"Could not download file (bad status code %ld)", (long)urlResponse.statusCode];
        *outError = [NSError errorWithDomain:kCTCFeedCheckerErrorDomain
                                        code:-7
                                    userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
        return nil;
    }
    
    NSLog(@"Download complete, filesize: %lu", (unsigned long)downloadedFile.length);
    
    // Try to get a nice filename, fall back on the suggested one, append extension if needed
    NSString *filename = [CTCFileUtils torrentFilenameFromString:file[@"title"] ?: urlResponse.suggestedFilename];
    
    // Compute destination path
    NSArray *pathComponents = downloadPath.pathComponents;
    if (folder) pathComponents = [pathComponents arrayByAddingObject:folder];
    NSString *pathAndFolder = [NSString pathWithComponents:pathComponents].stringByStandardizingPath;
    pathComponents = [pathComponents arrayByAddingObject:filename];
    NSString *pathAndFilename = [NSString pathWithComponents:pathComponents].stringByStandardizingPath;
    
    // Check if the destination dir exists, if it doesn't create it
    BOOL pathAndFolderIsDirectory = NO;
    if ([NSFileManager.defaultManager fileExistsAtPath:pathAndFolder
                                           isDirectory:&pathAndFolderIsDirectory]) {
        if (!pathAndFolderIsDirectory) {
            // Exists but isn't a directory! Aaargh! Abort!
            NSString *errorDescription = [NSString stringWithFormat:@"Download path is not a directory: %@", pathAndFolder];
            *outError = [NSError errorWithDomain:kCTCFeedCheckerErrorDomain
                                            code:-2
                                        userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
            return nil;
        }
    }
    else {
        // Create folder
        if (![NSFileManager.defaultManager createDirectoryAtPath:pathAndFolder
                                     withIntermediateDirectories:YES
                                                      attributes:nil
                                                           error:&error]) {
            // Folder creation failed :( Abort
            NSString *errorDescription = [NSString stringWithFormat:@"Couldn't create folder: %@", pathAndFolder];
            *outError = [NSError errorWithDomain:kCTCFeedCheckerErrorDomain
                                            code:-3
                                        userInfo:@{NSLocalizedDescriptionKey: errorDescription,
                                                   NSUnderlyingErrorKey: error}];
            return nil;
        }
        else {
            NSLog(@"Folder %@ created", pathAndFolder);
        }
    }
    
    // Write!
    BOOL wasWrittenSuccessfully = [downloadedFile writeToFile:pathAndFilename
                                                      options:NSDataWritingAtomic
                                                        error:&error];
    if (!wasWrittenSuccessfully) {
        NSString *errorDescription = [NSString stringWithFormat:@"Couldn't save file to disk: %@", pathAndFolder];
        *outError = [NSError errorWithDomain:kCTCFeedCheckerErrorDomain
                                        code:-4
                                    userInfo:@{NSLocalizedDescriptionKey: errorDescription,
                                               NSUnderlyingErrorKey: error}];
        return nil;
    }
    
    return pathAndFilename;
}

@end
