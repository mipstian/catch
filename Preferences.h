//
//  Preferences.h
//  Catch
//
//  Created by Giorgio Calderolla on 6/12/10.
//  Copyright 2010 n\a. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// NSUserDefaults keys
extern NSString* const PREFERENCE_KEY_FEED_URL;
extern NSString* const PREFERENCE_KEY_ONLY_UPDATE_BETWEEN;
extern NSString* const PREFERENCE_KEY_UPDATE_FROM;
extern NSString* const PREFERENCE_KEY_UPDATE_TO;
extern NSString* const PREFERENCE_KEY_SAVE_PATH;
extern NSString* const PREFERENCE_KEY_ORGANIZE_TORRENTS;
extern NSString* const PREFERENCE_KEY_OPEN_AUTOMATICALLY;
extern NSString* const PREFERENCE_KEY_GROWL_NOTIFICATIONS;
extern NSString* const PREFERENCE_KEY_CHECK_FOR_UPDATES;
extern NSString* const PREFERENCE_KEY_DOWNLOADED_FILES;
extern NSString* const PREFERENCE_KEY_OPEN_AT_LOGIN;
extern int const FEED_UPDATE_INTERVAL;


@interface Preferences : NSObject {
}

- (void) setDefaults;

- (void) save;

- (BOOL) validate;

@end
