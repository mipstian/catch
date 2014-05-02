#import "CTCFeedChecker.h"
#import "CTCFeedParser.h"
#import "CTCFileUtils.h"


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
    
    NSMutableArray *downloadedFeedFiles = NSMutableArray.array;
    
    // Flush the cache, we want fresh results
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    
    // Download the feed
    NSXMLDocument* feed = [self downloadFeed:feedURL];
    
    if (!feed) {
        reply(NO, downloadedFeedFiles);
        return;
    }
    
    // Parse the feed for files
    NSArray* feedFiles = [CTCFeedParser parseURLs:feed];
    if (!feedFiles) {
        reply(NO, downloadedFeedFiles);
        return;
    }
    
    // Parse the feed for show folders
    NSArray* feedShowFolders = shouldOrganizeByFolder ? [CTCFeedParser parseFolders:feed] : nil;
    if (!feedShowFolders || feedFiles.count != feedShowFolders.count) {
        // Make sure we have good folders
        feedShowFolders = nil;
        NSLog(@"Error parsing show folders, folders will not be used");
    }
    
    // Download the files
    if (![self downloadFiles:feedFiles
                      toPath:downloadFolderPath
                   inFolders:feedShowFolders
                skippingURLs:previouslyDownloadedURLs]) {
        reply(NO, downloadedFeedFiles);
        return;
    }
    
    NSLog(@"All done");
    
    reply(YES, downloadedFeedFiles);
}

- (NSXMLDocument*)downloadFeed:(NSURL*)feedURL {
	NSLog(@"Downloading feed %@", feedURL);
	
	NSError* error = nil;
	
	// Create a NSXMLDocument by downloading feed
	NSXMLDocument* document = [[NSXMLDocument alloc] initWithContentsOfURL:feedURL options:NSXMLNodeOptionsNone error:&error];
	
	if (document) {
		NSLog(@"Feed downloaded");
	} else {
		NSLog(@"Feed download failed: %@", error);
	}
	
	return document;
}

- (BOOL)downloadFiles:(NSArray *)files
               toPath:(NSString *)downloadPath
            inFolders:(NSArray *)fileFolders
         skippingURLs:(NSArray *)previouslyDownloadedURLs {
	NSLog(@"Downloading files (if needed)");
	
	BOOL downloadingFailed = NO;
	
	for (NSDictionary* file in files) {
		// Skip old files
		NSString* url = file[@"url"];
		
		if (previouslyDownloadedURLs) {
            if ([previouslyDownloadedURLs containsObject:url]) continue;
		}
		
		// The file is new, open magnet or download torrent
		if ([url rangeOfString:@"magnet:"].location == 0) {
            NSLog(@"Found magnet %@ at %@", file[@"title"], url);
            downloadingFailed = ![NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:url]];
		} else {
			NSLog(@"Found file %@ at %@", file[@"title"], url);
			// First get the folder, if available
			NSString* folder = fileFolders[[files indexOfObject:file]];
			downloadingFailed = (![self downloadFile:[NSURL URLWithString:url]
                                              toPath:downloadPath
                                        inShowFolder:folder]);
		}
        
		if (downloadingFailed) {
			NSLog(@"Could not download %@", url);
		} else {
			// Notify of addition
			if ([[NSUserDefaults standardUserDefaults] boolForKey:PREFERENCE_KEY_SEND_NOTIFICATIONS]) {
				[[NSApp delegate] torrentNotificationWithDescription:
				 [NSString stringWithFormat:NSLocalizedString(@"newtorrentdesc", @"New torrent notification"), [file objectForKey:@"title"]]];
			}
			
			// Add url to history
			NSArray* newDownloadedFiles = nil;
			
			if (downloadedFiles) {
				// Other old downloads are there. Add the new one
				newDownloadedFiles = [downloadedFiles arrayByAddingObject:file];
			} else {
				// First download ever. Initialize the preference
				newDownloadedFiles = [NSArray arrayWithObject:file];
			}
			[[NSUserDefaults standardUserDefaults]
			 setObject:newDownloadedFiles
			 forKey:PREFERENCE_KEY_HISTORY];
		}
	}
	
	if (downloadingFailed) return NO;
	
	return YES;
}

- (BOOL)downloadFile:(NSURL *)fileURL
              toPath:(NSString *)downloadPath
        inShowFolder:(NSString *)folder {
	if (folder) NSLog(@"Downloading file %@ in folder %@",fileURL,folder);
	else NSLog(@"Downloading file %@",fileURL);
	
	NSError* error = nil;
	
	// Download!
	NSData* downloadedFile = nil;
	NSURLRequest* urlRequest = [[NSURLRequest alloc] initWithURL:fileURL];
	NSURLResponse* urlResponse = [[NSURLResponse alloc] init];
	NSError* downloadError = [[NSError alloc] init];
	downloadedFile = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&urlResponse error:&downloadError];
	
	if (!downloadedFile) return NO;
    
	NSLog(@"Download complete, filesize: %lu", (unsigned long)downloadedFile.length);
	
	// Get the suggested filename, append extension if needed
	NSString* filename = [urlResponse suggestedFilename];
	filename = [CTCFileUtils addTorrentExtensionTo:filename];
    
	// Compute destination path
	NSArray* pathComponents = [downloadPath pathComponents];
	if (folder) pathComponents = [pathComponents arrayByAddingObject:folder];
	NSString* pathAndFolder = [[NSString pathWithComponents:pathComponents] stringByStandardizingPath];
	pathComponents = [pathComponents arrayByAddingObject:filename];
	NSString* pathAndFilename = [[NSString pathWithComponents:pathComponents] stringByStandardizingPath];
	
	NSLog(@"Computed file destination %@", pathAndFilename);
	
	// Check if the destination dir exists, if it doesn't create it
	BOOL pathAndFolderIsDirectory = NO;
	if ([[NSFileManager defaultManager] fileExistsAtPath:pathAndFolder isDirectory:&pathAndFolderIsDirectory]) {
		if (!pathAndFolderIsDirectory) {
			// Exists but isn't a directory! Aaargh! Abort!
			return NO;
		}
        
	} else {
		// Create folder
		if (![[NSFileManager defaultManager] createDirectoryAtPath:pathAndFolder
                                       withIntermediateDirectories:YES
                                                        attributes:nil
                                                             error:&error]) {
			// Folder creation failed :( Abort
			NSLog(@"Couldn't create folder %@", pathAndFolder);
			return NO;
		} else {
			NSLog(@"Folder %@ created", pathAndFolder);
		}
	}
	
	// Write!
	if (![downloadedFile writeToFile:pathAndFilename atomically:YES]) {
		NSLog(@"Couldn't save file %@ to disk", pathAndFilename);
		return NO;
	}
	
	// open in default torrent client if the preferences say so
	if ([[NSUserDefaults standardUserDefaults] boolForKey:PREFERENCE_KEY_OPEN_AUTOMATICALLY]) {
		[[NSWorkspace sharedWorkspace] openFile:pathAndFilename];
	}
	
	return YES;
}

@end
