//
//	GUI.h
//	Catch
//
//	Created by Giorgio Calderolla on 6/12/10.
//	Copyright 2010 n\a. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTCAppDelegate.h"
#import "Preferences.h"


@interface GUI : NSObject <NSUserNotificationCenterDelegate> {
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
}

/* Show the Preferences window */
- (IBAction)showPreferences:(id)sender;

/* Set GUI widgets to reflect status */
- (void)setStatusActive:(BOOL)isActive running:(BOOL)isRunning;
- (void)setLastUpdateStatus:(int)status time:(NSDate*)time;
- (void)refreshRecent:(NSArray*)recentTorrents;

/* Notifications */
- (void)torrentNotificationWithDescription:(NSString*)description;

@end
