//
//  FeedChecker.h
//  Catch
//
//  Created by Giorgio Calderolla on 6/18/10.
//  Copyright 2010 n\a. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Preferences.h"


@interface FeedChecker : NSObject {
	Preferences* preferences;
}

- (id) initWithPreferences:(Preferences*)preferences;

- (BOOL) checkFeed;

- (NSXMLDocument*) downloadFeed:(NSURL*)feedURL;

- (BOOL) downloadFiles:(NSArray*)fileURLs inFolders:(NSArray*)fileFolders;

- (BOOL) downloadFile:(NSURL*)fileURL inFolder:(NSString*)folder;

+ (NSString*) computeFilenameFromURL:(NSURL*)fileURL;

+ (NSString*) addTorrentExtensionTo:(NSString*)filename;

- (NSArray*) parseURLs:(NSXMLDocument*)feed;

- (NSArray*) parseFolders:(NSXMLDocument*)feed;

@end
