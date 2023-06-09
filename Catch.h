//
//  Catch.h
//  Catch
//
//  Created by Giorgio Calderolla on 6/12/10.
//  Copyright 2010 n\a. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Preferences.h"
#import "Scheduler.h"
#import "FeedChecker.h"
@class GUI;

extern NSString* const APPLICATION_WEBSITE_URL;
extern NSString* const APPLICATION_BUG_REPORT_URL;
extern NSString* const APPLICATION_FEATURE_REQUEST_URL;
extern NSString* const APPLICATION_HELP_URL;
extern NSString* const SERVICE_URL;
extern NSString* const SERVICE_FEED_URL_PREFIX;
extern NSString* const SERVICE_FEED_LEGACY_URL_PREFIX;


@interface Catch : NSObject {
	IBOutlet GUI* gui;
	Scheduler* scheduler;
	FeedChecker* feedChecker;
}

- (id) init;

- (void) applicationDidFinishLaunching:(NSNotification*)aNotification;

- (void) schedulerStatus:(int)status running:(int)running;

- (void) lastUpdateStatus:(int)status time:(NSDate*)time;

- (void) checkNow;

- (void) togglePause;

- (void) savePreferences;

- (BOOL) isConfigurationValid;

- (void) torrentNotificationWithDescription:(NSString*)description;

- (void) orderFrontStandardAboutPanel:(id)sender;

- (void) quit;

@end
