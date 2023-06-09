//
//  Catch.m
//  Catch
//
//  Created by Giorgio Calderolla on 6/12/10.
//  Copyright 2010 n\a. All rights reserved.
//

#import "Catch.h"
#import "GUI.h"

// Constant, non-localized, non-UI-related strings
NSString* const APPLICATION_NAME = @"Catch";
NSString* const APPLICATION_VERSION = @"1.5";
NSString* const APPLICATION_WEBSITE_URL = @"http://github.com/showrss/catch";
NSString* const APPLICATION_BUG_REPORT_URL = @"https://github.com/showrss/catch/issues/new";
NSString* const APPLICATION_FEATURE_REQUEST_URL = @"https://github.com/showrss/catch/issues/new";
NSString* const APPLICATION_HELP_URL = @"https://github.com/showrss/catch/wiki/Help";
NSString* const SERVICE_URL = @"http://showrss.info/";
NSString* const SERVICE_FEED_URL_PREFIX = @"http://showrss.info/rss.php?";


@implementation Catch

- (id) init {
	NSLog(@"Catch: init, loading preferences");
	
	// Create preferences and set default values
	preferences = [[Preferences alloc] retain];
	[preferences setDefaults];
	[preferences save]; //This ensures we have the latest values from the user
	
	// Register as a login item if needed
	[self registerAsLoginItem:[[NSUserDefaults standardUserDefaults] boolForKey:PREFERENCE_KEY_OPEN_AT_LOGIN]];
	
	// Create a feed checker
	feedChecker = [[[FeedChecker alloc] initWithPreferences:preferences] retain];

	return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	NSLog(@"Catch: finished launching");
	
	// show Preferences folder if the config is not valid
	if (![preferences validate]) {
		[gui showPreferences:self];
	}
	
	NSLog(@"Catch: creating scheduler for feed checker");
	scheduler = [[[Scheduler alloc] initWithFeedChecker:feedChecker preferences:preferences] retain];
	
	// Also check now
	[scheduler forceCheck];
}

- (void) schedulerStatus:(int)status running:(int)running {
	[gui setStatus:status running:running];
}

- (void) lastUpdateStatus:(int)status time:(NSDate*)time {
	[gui setLastUpdateStatus:status time:time];
	
	// Also refresh the list of recently downloaded torrents
	// Get the full list
	NSArray* downloaded = [[NSUserDefaults standardUserDefaults] arrayForKey:PREFERENCE_KEY_DOWNLOADED_FILES];
	// Get last 10 elements
	NSRange recentRange;
	recentRange.length = ([downloaded count] > 10) ? 10 : [downloaded count];
	recentRange.location = [downloaded count] - recentRange.length;
	
	NSArray* recent = [downloaded subarrayWithRange:recentRange];
	NSArray* cleanRecent = [NSArray array];
	int count = [recent count];
	for (int i = 1; i <= count; i++) {
		NSString* clean = [FeedChecker computeFilenameFromURL:[NSURL URLWithString:[recent objectAtIndex:count-i]]];
		clean = [[NSString stringWithFormat:@"%d ",i] stringByAppendingString:clean];
		cleanRecent = [cleanRecent arrayByAddingObject:clean];
	}
	
	[gui refreshRecent:cleanRecent];
}

- (void) checkNow {
	[scheduler forceCheck];
}

- (void) togglePause {
	if ([scheduler pauseResume]) {
		// If the scheduler is now active, also force a check right away
		[scheduler forceCheck];
	}
}

- (void) savePreferences {
	[preferences save];
	
	// Register as a login item if needed
	[self registerAsLoginItem:[[NSUserDefaults standardUserDefaults] boolForKey:PREFERENCE_KEY_OPEN_AT_LOGIN]];
	
	// Also force check
	[self checkNow];
}

- (BOOL) isConfigurationValid {
	return [preferences validate];
}

- (void) torrentNotificationWithDescription:(NSString *)description {
	[gui torrentNotificationWithDescription:description];
}

- (void) registerAsLoginItem:(BOOL)enable {
	if (enable)	NSLog(@"Catch: adding myself to the login items");
	else NSLog(@"Catch: removing myself from the login items");
	
	// Code totally ripped off from:
	// http://cocoatutorial.grapewave.com/2010/02/creating-andor-removing-a-login-item/
	
	NSString * appPath = [[NSBundle mainBundle] bundlePath];
	CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:appPath]; 
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,
															kLSSharedFileListSessionLoginItems, NULL);
	
	if (!loginItems) {
		NSLog(@"Catch: couldn't add/remove myself to the login items :(");
		return;
	}
	
	if (enable) {
		// Add Catch to the login items
		LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItems,
																		kLSSharedFileListItemLast, NULL, NULL,
																		url, NULL, NULL);
		if (item){
			CFRelease(item);
		}
	} else {
		// Remove Catch from the login items
		UInt32 seedValue;
		NSArray  *loginItemsArray = (NSArray *)LSSharedFileListCopySnapshot(loginItems, &seedValue);
		int i = 0;
		for(i ; i< [loginItemsArray count]; i++){
			LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)[loginItemsArray
																		objectAtIndex:i];
			// Resolve the item with URL
			if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &url, NULL) == noErr) {
				NSString * urlPath = [(NSURL*)url path];
				if ([urlPath compare:appPath] == NSOrderedSame){
					// Here I am. Remove me please.
					LSSharedFileListItemRemove(loginItems,itemRef);
				}
			}
		}
		[loginItemsArray release];
	}

	CFRelease(loginItems);
}

- (void) orderFrontStandardAboutPanel:(id)sender {
	// Do nothing
}

- (void) quit {
	NSLog(@"Catch: quitting");
	// Save preferences
	[preferences save];
	
	NSLog(@"Catch: all done, bye bye");
	// Quit
	[NSApp terminate:nil];
}

@end
