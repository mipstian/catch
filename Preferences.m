//
//  Preferences.m
//  Catch
//
//  Created by Giorgio Calderolla on 6/12/10.
//  Copyright 2010 n\a. All rights reserved.
//

#import "Preferences.h"
#import "Catch.h"

NSString* const PREFERENCE_KEY_FEED_URL = @"feedURL";
NSString* const PREFERENCE_KEY_ONLY_UPDATE_BETWEEN = @"onlyUpdateBetween";
NSString* const PREFERENCE_KEY_UPDATE_FROM = @"updateFrom";
NSString* const PREFERENCE_KEY_UPDATE_TO = @"updateTo";
NSString* const PREFERENCE_KEY_SAVE_PATH = @"savePath";
NSString* const PREFERENCE_KEY_ORGANIZE_TORRENTS = @"organizeTorrents";
NSString* const PREFERENCE_KEY_OPEN_AUTOMATICALLY = @"openAutomatically";
NSString* const PREFERENCE_KEY_GROWL_NOTIFICATIONS = @"growlNotifications";
NSString* const PREFERENCE_KEY_CHECK_FOR_UPDATES = @"checkForUpdates";
NSString* const PREFERENCE_KEY_DOWNLOADED_FILES = @"downloadedFiles";
NSString* const PREFERENCE_KEY_OPEN_AT_LOGIN = @"openAtLogin";

// Defaults
int const FEED_UPDATE_INTERVAL = 60*10; // 10 minutes


@implementation Preferences

- (void) setDefaults {
	NSLog(@"Preferences: Setting defaults");
	// Create two dummy times (dates actually), just to have some value set
	NSDateComponents* comps = [[NSDateComponents alloc] init];
	[comps setHour:24];
	[comps setMinute:0];
	NSCalendar* calendar = [NSCalendar currentCalendar];
	NSDate* dateFrom = [calendar dateFromComponents:comps];
	[comps setHour:8];
	NSDate* dateTo = [calendar dateFromComponents:comps];
	[comps release];
	
	// Search for user's Downloads directory (by the book)
	NSString *downloadsDirectory;
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES);
	if ([paths count] > 0)  {
		downloadsDirectory = [paths objectAtIndex:0];
		NSLog(@"Preferences: Default save path is %@",downloadsDirectory);
	} else {
		// Default to ~/Downloads/ (at this point it probably won't work though)
		NSLog(@"Preferences: Defaulting to ~/Downloads/ for save path");
		downloadsDirectory = @"~/Downloads/";
	}
	
	// Set smart defaults for the preferences
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

	NSDictionary* appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"", PREFERENCE_KEY_FEED_URL,
								 [NSNumber numberWithInt:0], PREFERENCE_KEY_ONLY_UPDATE_BETWEEN,
								 dateFrom, PREFERENCE_KEY_UPDATE_FROM,
								 dateTo, PREFERENCE_KEY_UPDATE_TO,
								 downloadsDirectory, PREFERENCE_KEY_SAVE_PATH,
								 [NSNumber numberWithInt:0], PREFERENCE_KEY_ORGANIZE_TORRENTS,
								 [NSNumber numberWithInt:1], PREFERENCE_KEY_OPEN_AUTOMATICALLY,
								 [NSNumber numberWithInt:1], PREFERENCE_KEY_GROWL_NOTIFICATIONS,
								 [NSNumber numberWithInt:1], PREFERENCE_KEY_CHECK_FOR_UPDATES,
								 [NSNumber numberWithInt:1], PREFERENCE_KEY_OPEN_AT_LOGIN,
								 nil];

	[defaults registerDefaults:appDefaults];
}

- (void) save {
	NSLog(@"Preferences: Synchronizing");
	// Write preferences to disk
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL) validate {
	// Validate torrent folder. This should never fail!
	NSString* torrentFolder = [[NSUserDefaults standardUserDefaults] stringForKey:PREFERENCE_KEY_SAVE_PATH];
	torrentFolder = [torrentFolder stringByStandardizingPath];
	
	if (!torrentFolder) return NO;

	BOOL isDirectory = NO;
	if ([[NSFileManager defaultManager] fileExistsAtPath:torrentFolder isDirectory:&isDirectory]) {
		if (!isDirectory) return NO;
	} else {
		return NO;
	}

	// Most importantly, validate feed URL
	NSString* feedURL = [[NSUserDefaults standardUserDefaults] stringForKey:PREFERENCE_KEY_FEED_URL];
	NSRange range = [feedURL rangeOfString:SERVICE_FEED_URL_PREFIX];
	if (range.location != 0) {
		// The URL should start with the prefix!
		NSLog(@"1: %lu %lu", (unsigned long)range.location, (unsigned long)range.length);
		return NO;
	}
	range = [feedURL rangeOfString:@"namespaces"];
	if (range.location == NSNotFound) {
		// The URL should have the namespaces parameter set
		NSLog(@"2");
		return NO;
	}
	
	return YES;
}

@end
