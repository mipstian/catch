//
//	FeedChecker.m
//	Catch
//
//	Created by Giorgio Calderolla on 6/18/10.
//	Copyright 2010 n\a. All rights reserved.
//

#import "FeedChecker.h"
#import "Catch.h"


@implementation FeedChecker

- (BOOL) checkFeed {
	NSLog(@"FeedChecker: checking");
	
	// This autorelease pool is here because the containing one,
	// being in an infinite loop, never gets released. So this
	// avoids leaks in this class. God I miss Java.
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	// We don't want these preferences to change while we're working
	BOOL organize = [[NSUserDefaults standardUserDefaults] boolForKey:PREFERENCE_KEY_ORGANIZE_TORRENTS];
	NSURL* feedURL = [NSURL URLWithString:Preferences.feedURL];
	
	// Flush the cache, we want fresh results
	[[NSURLCache sharedURLCache] removeAllCachedResponses];
	
	// Download the feed
	NSXMLDocument* feed = [self downloadFeed:feedURL];
	
	if (!feed) return NO;
	
	// Parse the feed
	NSArray* fileURLs = [self parseURLs:feed];
	NSArray* fileFolders = nil;
	if (organize) fileFolders = [self parseFolders:feed];
	
	if (!fileURLs) return NO;
	
	if (!fileFolders || [fileURLs count] != [fileFolders count]) {
		// Make sure we have good folders
		fileFolders = nil;
		if (organize) {
			NSLog(@"FeedChecker: bad folders!");
		} else {
			NSLog(@"FeedChecker: user doesn't want folders");
		}
	}
	
	// Download the files
	if (![self downloadFiles:fileURLs inFolders:fileFolders]) {
		return NO;
	}
	 
	NSLog(@"FeedChecker: done!");
	
	[pool drain];
	
	return YES;
}

- (NSArray*) parseURLs:(NSXMLDocument*)feed {
	NSLog(@"FeedChecker: parsing feed for URLs");
	
	NSError* error = nil;
	
	// Get file URLs with XPath
	NSArray* fileNodes = [feed nodesForXPath:@"//rss/channel/item" error:&error];
	NSLog(@"File Nodes:	 %@", fileNodes);
	
	if (fileNodes) {
		NSLog(@"FeedChecker: got %lu files", (unsigned long)fileNodes.count);
	} else {
		NSLog(@"FeedChecker: parsing for URLs failed: %@", error);
		return nil;
	}
	
	// Extract URLs from NSXMLNodes
	NSMutableArray* fileURLs = [NSMutableArray arrayWithCapacity:[fileNodes count]];
	
	for(NSXMLNode* file in fileNodes) {
		NSString* url = [[[file nodesForXPath:@"enclosure/@url" error:&error] lastObject] stringValue];
		NSString* title = [[[file nodesForXPath:@"title" error:&error] lastObject] stringValue];
		NSLog(@"FeedChecker: got file: %@ at %@", title, url);
		[fileURLs addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							 title, @"title", url, @"url", nil]];
	}
	
	return fileURLs;
}

- (NSArray*) parseFolders:(NSXMLDocument*)feed {
	NSLog(@"FeedChecker: parsing feed for folders");
	
	NSError* error = nil;
	
	// Get file folders with XPath
	NSArray* folderNodes = [feed nodesForXPath:@"//rss/channel/item/showrss:showname" error:&error];
	
	if (folderNodes) {
		NSLog(@"FeedChecker: got %lu folders", (unsigned long)folderNodes.count);
	} else {
		NSLog(@"FeedChecker: parsing for folders failed: %@", error);
		return nil;
	}
	
	// Extract folders from NSXMLNodes
	NSMutableArray* fileFolders = [NSMutableArray arrayWithCapacity:[folderNodes count]];
	
	for(NSXMLNode* node in folderNodes) {
		NSString* folder = [node stringValue];
		folder = [folder stringByReplacingOccurrencesOfString:@"/" withString:@""]; // Strip slashes
		folder = [folder stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]; // Trim whitespace
		[fileFolders addObject:folder];
	}
	
	NSLog(@"FeedChecker: got folders:\n%@", fileFolders);
	
	return fileFolders;
}

- (NSXMLDocument*)downloadFeed:(NSURL*)feedURL {
	NSLog(@"FeedChecker: downloading feed");
	
	NSError* error = nil;
	
	// Create a NSXMLDocument by downloading feed
	NSXMLDocument* document = [[NSXMLDocument alloc] initWithContentsOfURL:feedURL options:NSXMLNodeOptionsNone error:&error];
	
	if (document) {
		NSLog(@"FeedChecker: feed downloaded, dump:\n%@", document);
	} else {
		NSLog(@"FeedChecker: feed download failed: %@", error);
	}
	
	return [document autorelease];
}

- (BOOL) downloadFiles:(NSArray*)files inFolders:(NSArray*)fileFolders {
	NSLog(@"FeedChecker: downloading files (if needed)");
	
	BOOL downloadingFailed = NO;
	
	for (NSDictionary* file in files) {
		// Skip old files
		BOOL old = NO;
		NSString* url = [file objectForKey:@"url"];
		
		NSArray* downloadedFiles = [[NSUserDefaults standardUserDefaults] arrayForKey:PREFERENCE_KEY_HISTORY];
		
		if (downloadedFiles) {
			for (NSDictionary* downloadedFile in downloadedFiles) {
				if ([url compare:[downloadedFile objectForKey:@"url"]] == NSOrderedSame) {
					old = YES;
					break;
				}
			}
			if (old) continue;
		}
		
		// The file is new, open magnet or download torrent
		if ([url rangeOfString:@"magnet:"].location == 0) {
				NSLog(@"FeedChecker: it's a magnet %@ at %@", [file objectForKey:@"title"], url);
				downloadingFailed = ![[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
		} else {
			NSLog(@"FeedChecker: it's a file %@ at %@", [file objectForKey:@"title"], url);
			// First get the folder, if available
			NSString* folder = [fileFolders objectAtIndex:[files indexOfObject:file]];
			downloadingFailed = (![self downloadFile:[NSURL URLWithString:url] inFolder:folder]);
		}
	
		if (downloadingFailed) {
			NSLog(@"FeedChecker: download of %@ failed",url);
		} else {
			// Notify of addition
			if ([[NSUserDefaults standardUserDefaults] boolForKey:PREFERENCE_KEY_GROWL_NOTIFICATIONS]) {
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

- (BOOL) downloadFile:(NSURL*)fileURL inFolder:(NSString*)folder {
	if (folder) NSLog(@"FeedChecker: downloading file %@ in folder %@",fileURL,folder);
	else NSLog(@"FeedChecker: downloading file %@",fileURL);
	
	NSError* error = nil;
	
	// Download!
	NSData* downloadedFile = nil;
	NSURLRequest* urlRequest = [[[NSURLRequest alloc] initWithURL:fileURL] autorelease];
	NSURLResponse* urlResponse = [[[NSURLResponse alloc] init] autorelease];
	NSError* downloadError = [[[NSError alloc] init] autorelease];
	downloadedFile = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&urlResponse error:&downloadError];
	
	if (!downloadedFile) return NO;

	NSLog(@"FeedChecker: download complete, filesize: %lu", (unsigned long)downloadedFile.length);
	
	// Get the suggested filename, append extension if needed
	NSString* filename = [urlResponse suggestedFilename];
	filename = [FeedChecker addTorrentExtensionTo:filename];

	// Compute destination path
	NSString* path = [[NSUserDefaults standardUserDefaults] stringForKey:PREFERENCE_KEY_SAVE_PATH];
	NSArray* pathComponents = [path pathComponents];
	if (folder) pathComponents = [pathComponents arrayByAddingObject:folder];
	NSString* pathAndFolder = [[NSString pathWithComponents:pathComponents] stringByStandardizingPath];
	pathComponents = [pathComponents arrayByAddingObject:filename];
	NSString* pathAndFilename = [[NSString pathWithComponents:pathComponents] stringByStandardizingPath];
	
	NSLog(@"FeedChecker: computed file destination %@", pathAndFilename);
	
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
			NSLog(@"FeedChecker: couldn't create folder %@", pathAndFolder);
			return NO;
		} else {
			NSLog(@"FeedChecker: folder %@ created", pathAndFolder);
		}
	}
	
	// Write!
	if (![downloadedFile writeToFile:pathAndFilename atomically:YES]) {
		NSLog(@"FeedChecker: couldn't save file %@ to disk", pathAndFilename);
		return NO;
	}
	
	// open in default torrent client if the preferences say so
	if ([[NSUserDefaults standardUserDefaults] boolForKey:PREFERENCE_KEY_OPEN_AUTOMATICALLY]) {
		[[NSWorkspace sharedWorkspace] openFile:pathAndFilename];
	}
	
	return YES;
}

+ (NSString*) computeFilenameFromURL:(NSURL*)fileURL {
	// Compute destination filename
	NSString* filename = [[[fileURL path] pathComponents] lastObject];
	filename = [filename stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]; // Reverse urlencode
	
	return filename;
}

+ (NSString*) addTorrentExtensionTo:(NSString*)filename {
	// Add .torrent extension if needed
	NSRange range = [filename rangeOfString:@".torrent"];
	if (range.location == NSNotFound || range.location + range.length != [filename length]) {
		return [filename stringByAppendingString:@".torrent"];
	} else return filename;
}

@end
