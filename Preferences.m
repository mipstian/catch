//
//	Preferences.m
//	Catch
//
//	Created by Giorgio Calderolla on 6/12/10.
//	Copyright 2010 n\a. All rights reserved.
//

#import "Preferences.h"
#import "CTCAppDelegate.h"
#import "CTCFileUtils.h"


NSString * const PREFERENCE_KEY_FEED_URL = @"feedURL";
NSString * const PREFERENCE_KEY_ONLY_UPDATE_BETWEEN = @"onlyUpdateBetween";
NSString * const PREFERENCE_KEY_UPDATE_FROM = @"updateFrom";
NSString * const PREFERENCE_KEY_UPDATE_TO = @"updateTo";
NSString * const PREFERENCE_KEY_SAVE_PATH = @"savePath";
NSString * const PREFERENCE_KEY_ORGANIZE_TORRENTS = @"organizeTorrents";
NSString * const PREFERENCE_KEY_OPEN_AUTOMATICALLY = @"openAutomatically";
NSString * const PREFERENCE_KEY_SEND_NOTIFICATIONS = @"growlNotifications";
NSString * const PREFERENCE_KEY_DOWNLOADED_FILES = @"downloadedFiles";
NSString * const PREFERENCE_KEY_HISTORY = @"history";
NSString * const PREFERENCE_KEY_OPEN_AT_LOGIN = @"openAtLogin";


@implementation Preferences

+ (void)setDefaults {
	NSLog(@"Preferences: Setting defaults");
	// Create two dummy times (dates actually), just to have some value set
	NSDateComponents *comps = NSDateComponents.new;
    comps.hour = 8;
    comps.minute = 0;
	NSCalendar *calendar = NSCalendar.currentCalendar;
	NSDate *dateFrom = [calendar dateFromComponents:comps];
	NSDate *dateTo = [calendar dateFromComponents:comps];
	
	// Search for user's Downloads directory (by the book)
	NSString *downloadsDirectory;
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES);
	if (paths.count > 0) {
		downloadsDirectory = paths.firstObject;
		NSLog(@"Preferences: Default save path is %@", downloadsDirectory);
	} else {
		// Default to ~/Downloads/ (at this point it probably won't work though)
		NSLog(@"Preferences: Defaulting to ~/Downloads/ for save path");
		downloadsDirectory = @"~/Downloads/";
	}
	
	// Set smart defaults for the preferences
	NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"", PREFERENCE_KEY_FEED_URL,
								 @NO, PREFERENCE_KEY_ONLY_UPDATE_BETWEEN,
								 dateFrom, PREFERENCE_KEY_UPDATE_FROM,
								 dateTo, PREFERENCE_KEY_UPDATE_TO,
								 downloadsDirectory, PREFERENCE_KEY_SAVE_PATH,
								 @NO, PREFERENCE_KEY_ORGANIZE_TORRENTS,
								 @YES, PREFERENCE_KEY_OPEN_AUTOMATICALLY,
								 @YES, PREFERENCE_KEY_SEND_NOTIFICATIONS,
								 @YES, PREFERENCE_KEY_OPEN_AT_LOGIN,
								 nil];

	[NSUserDefaults.standardUserDefaults registerDefaults:appDefaults];
    
	// Migrate the downloads history format. Change old array of strings to new dictionary format
	NSArray *downloadedFiles = [NSUserDefaults.standardUserDefaults arrayForKey:PREFERENCE_KEY_DOWNLOADED_FILES];
	NSArray *history = [NSUserDefaults.standardUserDefaults arrayForKey:PREFERENCE_KEY_HISTORY];
	if (downloadedFiles && !history) {
		NSLog(@"Preferences: Migrating download history to new format.");
		
		NSMutableArray *newDownloadedFiles = NSMutableArray.array;
		
		for (NSString *url in downloadedFiles) {
			[newDownloadedFiles addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                           [CTCFileUtils computeFilenameFromURL:[NSURL URLWithString:url]], @"title",
                                           url, @"url",
                                           nil]];
		}
		
		[NSUserDefaults.standardUserDefaults setObject:newDownloadedFiles
                                                forKey:PREFERENCE_KEY_HISTORY];
		[NSUserDefaults.standardUserDefaults removeObjectForKey:PREFERENCE_KEY_DOWNLOADED_FILES];
	}
    
    // If history was never set or migrated, init it to empty array
    if (!downloadedFiles && !history) {
        [NSUserDefaults.standardUserDefaults setObject:@[]
                                                forKey:PREFERENCE_KEY_HISTORY];
    }
}

+ (NSString *)feedURL {
	NSString *rawFeedURL = [NSUserDefaults.standardUserDefaults stringForKey:PREFERENCE_KEY_FEED_URL];
	return [rawFeedURL stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
}

+ (void)save {
	NSLog(@"Preferences: Synchronizing");
	// Write preferences to disk
	[NSUserDefaults.standardUserDefaults synchronize];
}

+ (BOOL)validate {
	// Validate torrent folder. This should never fail!
	NSString *torrentFolder = [NSUserDefaults.standardUserDefaults stringForKey:PREFERENCE_KEY_SAVE_PATH];
	torrentFolder = [torrentFolder stringByStandardizingPath];
	
	if (!torrentFolder) return NO;

	BOOL isDirectory = NO;
	if ([NSFileManager.defaultManager fileExistsAtPath:torrentFolder
                                           isDirectory:&isDirectory]) {
		if (!isDirectory) return NO;
	} else {
		return NO;
	}

	// Most importantly, validate feed URL
	NSString *feedURL = self.feedURL;
	NSRange range = [feedURL rangeOfString:SERVICE_FEED_URL_PREFIX];
	if (range.location != 0) {
		// Try the legacy URL prefix and consider that valid
		range = [feedURL rangeOfString:SERVICE_FEED_LEGACY_URL_PREFIX];
	}
	if (range.location != 0) {
		// The URL should start with the prefix!
		NSLog(@"Feed URL does not start with expected prefix. Range of expected prefix: %lu %lu", (unsigned long)range.location, (unsigned long)range.length);
		return NO;
	}
	range = [feedURL rangeOfString:@"namespaces"];
	if (range.location == NSNotFound) {
		// The URL should have the namespaces parameter set
		NSLog(@"Feed URL does not have namespaces enabled");
		return NO;
	}
	
	return YES;
}

@end
