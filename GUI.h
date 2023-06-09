//
//	GUI.h
//	Catch
//
//	Created by Giorgio Calderolla on 6/12/10.
//	Copyright 2010 n\a. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Growl.framework/Headers/GrowlApplicationBridge.h"
#import "Catch.h"
#import "Preferences.h"


@interface GUI : NSObject <GrowlApplicationBridgeDelegate,	NSUserNotificationCenterDelegate> {
	// Outlets and UI components
	IBOutlet NSMenu* menu;
	IBOutlet NSMenuItem* menuVersion;
	IBOutlet NSMenuItem* menuCheckNow;
	IBOutlet NSMenuItem* menuPauseResume;
	IBOutlet NSMenuItem* menuLastUpdate;
	IBOutlet NSMenuItem* menuRecentTorrents;
	IBOutlet NSMenuItem* menuShowInFinder;
	IBOutlet NSWindow* preferencesWindow;
	IBOutlet NSTabView* preferencesTabs;
	NSStatusItem* item;
	BOOL notificationCenterIsAvailable;
	
	// Images
	NSImage* iconIdle;
	NSImage* iconIdleInv;
	NSImage* iconRefreshing;
	NSImage* iconRefreshingInv;
	NSImage* iconDisabled;
	NSImage* iconDisabledInv;
}

/* Launch the system browser, open the service (ShowRSS) */
- (IBAction)browseService:(id)sender;

/* Launch the system browser, open the applications's website */
- (IBAction)browseWebsite:(id)sender;

/* Launch the system browser, open the applications's on-line help */
- (IBAction)browseHelp:(id)sender;

/* Launch the system browser, open the applications's feature request page */
- (IBAction)browseFeatureRequest:(id)sender;

/* Launch the system browser, open the applications's bug report page */
- (IBAction)browseBugReport:(id)sender;

/* Open the torrents folder in Finder */
- (IBAction)openTorrentFolder:(id)sender;

/* Show the Preferences window */
- (IBAction)showPreferences:(id)sender;

/* Save the preferences and close the Preferences window */
- (IBAction)savePreferences:(id)sender;

/* Shows the Feeds view in the preferences */
- (IBAction)showFeeds:(id)sender;

/* Shows the Tweaks view in the preferences */
- (IBAction)showTweaks:(id)sender;

/* Forces a feed check */
- (IBAction)checkNow:(id)sender;

/* Pauses/Resumes feed checking */
- (IBAction)togglePause:(id)sender;

/* Cleanly quits */
- (IBAction)quit:(id)sender;

/* Set GUI widgets to reflect status */
- (void)setStatus:(int)status running:(int)running;
- (void)setLastUpdateStatus:(int)status time:(NSDate*)time;
- (void)setMenuLastUpdateStatus:(NSString*)title;
- (void)refreshRecent:(NSArray*)recentTorrents;

/* Errors */
- (void)showBadURLSheet;

/* Growl stuff */
- (NSDictionary*)registrationDictionaryForGrowl;
- (NSString*)applicationNameForGrowl;
- (void)torrentNotificationWithDescription:(NSString*)description;

@end
