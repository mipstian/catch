//
//  FeedChecker.h
//  Catch
//
//  Created by Giorgio Calderolla on 6/12/10.
//  Copyright 2010 n\a. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Preferences.h"
#import "FeedChecker.h"


@interface Scheduler : NSObject {
	NSAutoreleasePool* pool;
	NSRunLoop* runLoop;
	NSTimer* repeatingTimer;
	FeedChecker* feedChecker;
	Preferences* preferences;
	int active;
	int running;
}

- (id) initWithFeedChecker:(FeedChecker*)theFeedChecker preferences:(Preferences*)thePreferences;

- (BOOL) pauseResume;

- (void) forceCheck;

- (void) tick:(NSTimer*)timer;

- (BOOL) checkTime;

@end
