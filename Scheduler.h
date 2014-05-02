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
	NSTimer* repeatingTimer;
	FeedChecker* feedChecker;
	int active;
	int running;
}

- (id)initWithFeedChecker:(FeedChecker*)theFeedChecker;

- (BOOL)pauseResume;

- (void)forceCheck;

@end
