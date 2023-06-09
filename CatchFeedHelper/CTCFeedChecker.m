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
       downloadingToPath:(NSString *)downloadFolderPath
      organizingByFolder:(BOOL)shouldOrganizeByFolder
            skippingURLs:(NSArray *)previouslyDownloadedURLs
               withReply:(CTCFeedCheckCompletionHandler)reply {
    NSLog(@"Checking feed");
    
    // Flush the cache, we want fresh results
    [NSURLCache.sharedURLCache removeAllCachedResponses];
    
    // Download the feed
    NSXMLDocument *feed = [self downloadFeed:feedURL];
    if (!feed) {
        reply(@[], [NSError errorWithDomain:kCTCFeedCheckerErrorDomain
                                       code:-1
                                   userInfo:nil]);
        return;
    }
    
    // Parse the feed for files
    NSArray *feedFiles = [CTCFeedParser parseURLs:feed];
    if (!feedFiles) {
        reply(@[], [NSError errorWithDomain:kCTCFeedCheckerErrorDomain
                                       code:-2
                                   userInfo:nil]);
        return;
    }
    
    // Parse the feed for show folders
    NSArray *feedShowFolders = shouldOrganizeByFolder ? [CTCFeedParser parseFolders:feed] : nil;
    if (!feedShowFolders) {
        NSLog(@"Error parsing show folders, folders will not be used");
    }
    else if (feedFiles.count != feedShowFolders.count) {
        NSLog(@"Missing show folders for some feed files, folders will not be used");
        feedShowFolders = nil;
    }
    
    // Download the files
    NSError *error;
    NSArray *downloadedFeedFiles = [self downloadFiles:feedFiles
                                                toPath:downloadFolderPath
                                             inFolders:feedShowFolders
                                          skippingURLs:previouslyDownloadedURLs
                                                 error:&error];
    
    NSLog(@"All done");
    
    reply(downloadedFeedFiles, error);
}

- (NSXMLDocument*)downloadFeed:(NSURL*)feedURL {
	NSLog(@"Downloading feed %@", feedURL);
	
	NSError *error = nil;
	
	// Create a NSXMLDocument by downloading feed
	NSXMLDocument *document = [[NSXMLDocument alloc] initWithContentsOfURL:feedURL options:NSXMLNodeOptionsNone error:&error];
	
	if (document) {
		NSLog(@"Feed downloaded");
	} else {
		NSLog(@"Feed download failed: %@", error);
	}
	
	return document;
}

- (NSArray *)downloadFiles:(NSArray *)feedFiles
                    toPath:(NSString *)downloadPath
                 inFolders:(NSArray *)fileFolders
              skippingURLs:(NSArray *)previouslyDownloadedURLs
                     error:(NSError * __autoreleasing *)error {
	NSLog(@"Downloading files (if needed)");
	
    NSMutableArray *successfullyDownloadedFeedFiles = NSMutableArray.array;
    
	for (NSDictionary *file in feedFiles) {
		NSString *url = file[@"url"];
		
        // Skip old files
        if ([previouslyDownloadedURLs containsObject:url]) continue;
        
        BOOL isMagnetLink = [url rangeOfString:@"magnet:"].location == 0;
		
		// The file is new, open magnet or download torrent
		if (isMagnetLink) {
            NSLog(@"Found magnet %@ at %@", file[@"title"], url);
            
            [successfullyDownloadedFeedFiles addObject:@{@"url": file[@"url"],
                                                         @"title": file[@"title"],
                                                         @"isMagnetLink": @YES}];
		} else {
			NSLog(@"Found file %@ at %@", file[@"title"], url);
            
			// First get the folder, if available
			NSString *folder = fileFolders[[feedFiles indexOfObject:file]];
            NSString *downloadedTorrentFile = [self downloadFile:[NSURL URLWithString:url]
                                                          toPath:downloadPath
                                                    inShowFolder:folder];
            if (downloadedTorrentFile) {
                [successfullyDownloadedFeedFiles addObject:@{@"url": file[@"url"],
                                                             @"title": file[@"title"],
                                                             @"isMagnetLink": @NO,
                                                             @"torrentFilePath": downloadedTorrentFile}];
            }
            else {
                NSLog(@"Could not download %@", url);
                *error = [NSError errorWithDomain:kCTCFeedCheckerErrorDomain
                                             code:-3
                                         userInfo:nil];
            }
		}
	}
	
	return successfullyDownloadedFeedFiles.copy;
}

- (NSString *)downloadFile:(NSURL *)fileURL
                    toPath:(NSString *)downloadPath
              inShowFolder:(NSString *)folder {
	if (folder) NSLog(@"Downloading file %@ in folder %@",fileURL,folder);
	else NSLog(@"Downloading file %@",fileURL);
	
	NSError *error = nil;
	
	// Download!
	NSData *downloadedFile = nil;
	NSURLRequest *urlRequest = [[NSURLRequest alloc] initWithURL:fileURL];
	NSURLResponse *urlResponse = [[NSURLResponse alloc] init];
	NSError *downloadError = [[NSError alloc] init];
	downloadedFile = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&urlResponse error:&downloadError];
	
	if (!downloadedFile) return nil;
    
	NSLog(@"Download complete, filesize: %lu", (unsigned long)downloadedFile.length);
	
	// Get the suggested filename, append extension if needed
	NSString *filename = [urlResponse suggestedFilename];
	filename = [CTCFileUtils addTorrentExtensionTo:filename];
    
	// Compute destination path
	NSArray *pathComponents = [downloadPath pathComponents];
	if (folder) pathComponents = [pathComponents arrayByAddingObject:folder];
	NSString *pathAndFolder = [[NSString pathWithComponents:pathComponents] stringByStandardizingPath];
	pathComponents = [pathComponents arrayByAddingObject:filename];
	NSString *pathAndFilename = [[NSString pathWithComponents:pathComponents] stringByStandardizingPath];
	
	NSLog(@"Computed file destination %@", pathAndFilename);
	
	// Check if the destination dir exists, if it doesn't create it
	BOOL pathAndFolderIsDirectory = NO;
	if ([NSFileManager.defaultManager fileExistsAtPath:pathAndFolder isDirectory:&pathAndFolderIsDirectory]) {
		if (!pathAndFolderIsDirectory) {
			// Exists but isn't a directory! Aaargh! Abort!
			return nil;
		}
	} else {
		// Create folder
		if (![NSFileManager.defaultManager createDirectoryAtPath:pathAndFolder
                                     withIntermediateDirectories:YES
                                                      attributes:nil
                                                           error:&error]) {
			// Folder creation failed :( Abort
			NSLog(@"Couldn't create folder %@", pathAndFolder);
			return nil;
		} else {
			NSLog(@"Folder %@ created", pathAndFolder);
		}
	}
	
	// Write!
	if (![downloadedFile writeToFile:pathAndFilename atomically:YES]) {
		NSLog(@"Couldn't save file %@ to disk", pathAndFilename);
		return nil;
	}
	
	return pathAndFilename;
}

@end
