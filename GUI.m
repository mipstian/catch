//
//	GUI.m
//	Catch
//
//	Created by Giorgio Calderolla on 6/12/10.
//	Copyright 2010 n\a. All rights reserved.
//

#import "GUI.h"

// Growl notification IDs
static NSString* const GROWL_NEW_TORRENT = @"New torrent";


@implementation GUI

- (void)awakeFromNib {
	// Load the (hidden) menu
	[NSBundle loadNibNamed:@"MainMenu" owner:[NSApp delegate]];
	 
	// Create the NSStatusBar and set its length
	item = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
	
	// Update status UI
	[self setStatus:1 running:0];
	[self setLastUpdateStatus:1 time:nil];

	// Tell the NSStatusItem what menu to load
	[item setMenu:menu];
	// Set the tooptip for our item
	[item setToolTip:[NSString stringWithFormat:@"%@ %@", APPLICATION_NAME, APPLICATION_VERSION] ];
	// Enable highlighting
	[item setHighlightMode:YES];
	// Set current name and version
	[menuVersion setTitle:[NSString stringWithFormat:@"%@ %@", APPLICATION_NAME, APPLICATION_VERSION] ];

	// Enable Growl
	notificationCenterIsAvailable = (NSClassFromString(@"NSUserNotificationCenter")!=nil);
	if (notificationCenterIsAvailable) {
		[[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
	} else {
		[GrowlApplicationBridge setGrowlDelegate:self];
	}
	
	// Select the first tab of the Preferences
	[self showFeeds:self];
	
	// Disable the recent torrents menu unitl there's something to show
	[menuRecentTorrents setEnabled:NO];
}

- (IBAction)browseService:(id)sender {
	// Launch the system browser, open the service (ShowRSS)
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:SERVICE_URL]];
}

- (IBAction)browseWebsite:(id)sender {
	// Launch the system browser, open the applications's website
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:APPLICATION_WEBSITE_URL]];
}

- (IBAction)browseHelp:(id)sender {
	// Launch the system browser, open the applications's on-line help
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:APPLICATION_HELP_URL]];
}

- (IBAction)browseFeatureRequest:(id)sender {
	// Launch the system browser, open the applications's feature request page
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:APPLICATION_FEATURE_REQUEST_URL]];
}

- (IBAction)browseBugReport:(id)sender {
	// Launch the system browser, open the applications's bug report page
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:APPLICATION_BUG_REPORT_URL]];
}

- (IBAction)openTorrentFolder:(id)sender {
	// Launch finder with the torrent folder open
	if ([[NSApp delegate] isConfigurationValid]) {
		NSString* torrentFolder = [[NSUserDefaults standardUserDefaults] stringForKey:PREFERENCE_KEY_SAVE_PATH];
		torrentFolder = [torrentFolder stringByStandardizingPath];
		[[NSWorkspace sharedWorkspace] openFile:[torrentFolder stringByStandardizingPath]];
	}
}

- (IBAction)showPreferences:(id)sender {
	// Show the Preferences window
	[NSApp activateIgnoringOtherApps:YES];
	[preferencesWindow makeKeyAndOrderFront:self];
}

- (IBAction)savePreferences:(id)sender {
	// Save preferences
	[[NSApp delegate] savePreferences];
	
	if ([[NSApp delegate] isConfigurationValid]) {
		// Hide the Preferences window
		[preferencesWindow close];
	} else {
		// The feed URL is probably invalid, warn user
		[self showBadURLSheet];
	}
}

- (IBAction)showFeeds:(id)sender {
	// Select the Feeds tab
	[[preferencesWindow toolbar] setSelectedItemIdentifier:@"Feeds"];
	[preferencesTabs selectFirstTabViewItem:self];
}

- (IBAction)showTweaks:(id)sender {
	// Select the Tweaks tab
	[[preferencesWindow toolbar] setSelectedItemIdentifier:@"Tweaks"];
	[preferencesTabs selectLastTabViewItem:self];
}

- (IBAction)checkNow:(id)sender {
	[[NSApp delegate] checkNow];
}

- (IBAction)togglePause:(id)sender {
	[[NSApp delegate] togglePause];
}

- (IBAction)quit:(id)sender {
	[[NSApp delegate] quit];
}

- (void)setStatus:(int)status running:(int)running {
	SEL action = nil;
	
	if (running) {
		action = @selector(setRefreshing);
	} else {
		if (status) {
			action = @selector(setIdle);
		} else {
			action = @selector(setDisabled);
		}
	}

	[self performSelectorOnMainThread:action withObject:nil waitUntilDone:YES];
}

- (void)setLastUpdateStatus:(int)status time:(NSDate *)time {
	// Create something like "Last update: 3:45 AM" and place it in the menu
	NSString* baseLastUpdateString = nil;
	NSString* lastUpdateString = nil;
	
	if (status) {
		baseLastUpdateString = NSLocalizedString(@"lastupdate", @"Title for the last update time");
	} else {
		baseLastUpdateString = NSLocalizedString(@"lastupdatefailed", @"Title for the last update time if it fails");
	}

	if (time) {
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		NSString* lastUpdateTime = [dateFormatter stringFromDate:time];
		[dateFormatter release];
		lastUpdateString = [NSString stringWithFormat:baseLastUpdateString,lastUpdateTime];
	} else {
		lastUpdateString = [NSString stringWithFormat:baseLastUpdateString,NSLocalizedString(@"never", @"Never happened")];
	}
	
	[self performSelectorOnMainThread:@selector(setMenuLastUpdateStatus:) withObject:lastUpdateString waitUntilDone:YES];
}

- (void)setMenuLastUpdateStatus:(NSString*)title {
	[menuLastUpdate setTitle:title];
}

- (void)setIdle {
	// Sets the images (status: idle)
	[item setImage:[NSImage imageNamed:@"menubar_idle"]];
	[item setAlternateImage:[NSImage imageNamed:@"menubar_idle-inv"]];
	
	// Enable "check now" menu
	[menuCheckNow setEnabled:YES];
	
	// Set pause/resume to "pause"
	[menuPauseResume setTitle:NSLocalizedString(@"pause", @"Description of pause action")];
}

- (void)setRefreshing {
	// Sets the images (status: refreshing)
	[item setImage:[NSImage imageNamed:@"menubar_refreshing"]];
	[item setAlternateImage:[NSImage imageNamed:@"menubar_refreshing-inv"]];
	
	// Disable "check now" menu
	[menuCheckNow setEnabled:NO];
	
	// Set pause/resume to "pause"
	[menuPauseResume setTitle:NSLocalizedString(@"pause", @"Description of pause action")];
	
	// Also overwrite the last update string with "Updating now"
	[menuLastUpdate setTitle:NSLocalizedString(@"updatingnow", @"An update is in progress")];
}

- (void)setDisabled {
	// Sets the images (status: disabled)
	[item setImage:[NSImage imageNamed:@"menubar_disabled"]];
	[item setAlternateImage:[NSImage imageNamed:@"menubar_disabled-inv"]];
	
	// Disable "check now" menu
	[menuCheckNow setEnabled:NO];
	
	// Set pause/resume to "resume"
	[menuPauseResume setTitle:NSLocalizedString(@"resume", @"Description of resume action")];
}

- (void)refreshRecent:(NSArray*)recentTorrents {
	[self performSelectorOnMainThread:@selector(refreshMenuWithRecent:) withObject:recentTorrents waitUntilDone:YES];
}

- (void)refreshMenuWithRecent:(NSArray *)recentTorrents {
	[menuShowInFinder retain];
	
	// Clear menu
	NSArray* items = [[menuRecentTorrents submenu] itemArray];
	for (NSMenuItem* menuItem in items) {
		[[menuRecentTorrents submenu] removeItem:menuItem];
	}
	
	// Add new items
	for (NSString* title in recentTorrents) {
		NSMenuItem* newItem = [[NSMenuItem alloc] initWithTitle:title action:NULL keyEquivalent:@""];
		[newItem setEnabled:NO];
		[[menuRecentTorrents submenu] addItem:newItem];
		[newItem release];
	}
	
	// Put the Show in finder menu back
	[[menuRecentTorrents submenu] addItem:menuShowInFinder];
	
	[menuShowInFinder release];

	[menuRecentTorrents setEnabled:YES];
}

- (void)showBadURLSheet {
	[self showFeeds:self];
	
	// Show a sheet warning the user: the feed URL is invalid
	NSBeginAlertSheet(
					  NSLocalizedString(@"badurl", @"Message for bad feed URL in preferences"),
					  NSLocalizedString(@"badurlok", @"OK Button for bad feed URL in preferences"),
					  nil,nil,preferencesWindow,self,
					  NULL,NULL,
					  nil,@"");
}

- (NSDictionary*)registrationDictionaryForGrowl {
	// Let Growl know about our notifications
	NSArray* notifications = [NSArray arrayWithObjects:GROWL_NEW_TORRENT,nil];
	NSDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
							[NSNumber numberWithInt:1], @"TicketVersion",
							notifications, @"AllNotifications",
							notifications, @"DefaultNotifications",
							nil];
	return dictionary;
}

- (NSString*)applicationNameForGrowl {
	return APPLICATION_NAME;
}

- (void)torrentNotificationWithDescription:(NSString*)description {
	if (notificationCenterIsAvailable) {
		NSUserNotification *notification = [[NSUserNotification alloc] init];
		notification.title = NSLocalizedString(@"newtorrent", @"New torrent notification");
		notification.informativeText = description;
		notification.soundName = NSUserNotificationDefaultSoundName;
		[[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
		[notification release];
	} else {
		[GrowlApplicationBridge notifyWithTitle:NSLocalizedString(@"newtorrent", @"New torrent notification")
									 description:description notificationName:GROWL_NEW_TORRENT
										iconData:nil priority:0 isSticky:NO
									clickContext:nil];
	}
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
	 shouldPresentNotification:(NSUserNotification *)notification
{
	return YES;
}

@end
