	//
//  FeedChecker.m
//  Catch
//
//  Created by Giorgio Calderolla on 6/12/10.
//  Copyright 2010 n\a. All rights reserved.
//

#import "Scheduler.h"
#import "Catch.h"


@implementation Scheduler

- (id) initWithFeedChecker:(FeedChecker*)theFeedChecker preferences:(Preferences*)thePreferences {
	active = 1;
	running = 0;
	
	feedChecker = [theFeedChecker retain];
	preferences = [thePreferences retain];
	
	// run a runloop in another thread
	[self performSelectorInBackground:@selector(loopRun) withObject:nil];
	
	return self;
}

- (void) loopRun {
	NSLog(@"Scheduler: running RunLoop");
	
	pool = [[NSAutoreleasePool alloc] init];
	
	runLoop = [[NSRunLoop currentRunLoop] retain];
	
	repeatingTimer = [[NSTimer scheduledTimerWithTimeInterval:FEED_UPDATE_INTERVAL
													   target:self
													 selector:@selector(tick:) 
													 userInfo:nil
													  repeats:YES]
					  retain];
	[runLoop addTimer:repeatingTimer forMode:NSDefaultRunLoopMode];
	[runLoop run];
	
	[pool release];
}

- (void) reportStatus {
	// Call to this method are performed on the main thread to get them out
	// in the right order
	NSLog(@"Scheduler: reporting status: active = %d, running = %d",active,running);
	
	// Report status to application controller
	[[NSApp delegate] schedulerStatus:active running:running];
}

- (BOOL) pauseResume {
	active = !active;
	
	[self performSelectorOnMainThread:@selector(reportStatus) withObject:nil waitUntilDone:NO];
	
	return (BOOL) active;
}

- (void) forceCheck {
	NSLog(@"Scheduler: forcing check");
	// Set the next timer fire date to be ASAP
	[repeatingTimer setFireDate:[NSDate distantPast]];
}

- (void) tick:(NSTimer*)timer {
	NSLog(@"Scheduler: tick");
	
	BOOL status = NO;
	
	if (!active) {
		NSLog(@"Scheduler: tick skipped, paused");
		return;
	}
	
	// Only work with valid preferences
	if (![preferences validate]) {
		NSLog(@"Scheduler: tick skipped, invalid preferences");
		return;
	}
	
	// Don't check if current time is outside user-defined range
	if ([[NSUserDefaults standardUserDefaults] boolForKey:PREFERENCE_KEY_ONLY_UPDATE_BETWEEN]) {
		if (![self checkTime]) {
			NSLog(@"Scheduler: tick skipped, outside of user-defined time range");
			return;
		}
	}
	
	running = 1;
	
	[self performSelectorOnMainThread:@selector(reportStatus) withObject:nil waitUntilDone:NO];
	
	status = [feedChecker checkFeed];
	
	running = 0;
	
	[self performSelectorOnMainThread:@selector(reportStatus) withObject:nil waitUntilDone:NO];
	
	[[NSApp delegate] lastUpdateStatus:status time:[NSDate date]];
}
			
- (BOOL) checkTime {
	BOOL timeInRange = YES;
	
	NSDate* now = [NSDate date];
	NSDate* from = (NSDate*) [[NSUserDefaults standardUserDefaults] objectForKey:PREFERENCE_KEY_UPDATE_FROM];
	NSDate* to = (NSDate*) [[NSUserDefaults standardUserDefaults] objectForKey:PREFERENCE_KEY_UPDATE_TO];
	
	NSCalendar* calendar = [NSCalendar currentCalendar];
	
	// Get minutes and hours from each date
	NSDateComponents* nowComp = [calendar components:NSHourCalendarUnit|NSMinuteCalendarUnit
												   fromDate:now];
	NSDateComponents* fromComp = [calendar components:NSHourCalendarUnit|NSMinuteCalendarUnit
													fromDate:from];
	NSDateComponents* toComp = [calendar components:NSHourCalendarUnit|NSMinuteCalendarUnit
												  fromDate:to];
	
	if ([fromComp hour] > [toComp hour] ||
		([fromComp hour] == [toComp hour] && [fromComp minute] > [toComp minute])) {
		// Time range crosses midnight (e.g. 11 PM to 3 AM)
		if (([nowComp hour] > [toComp hour] && [nowComp hour] < [fromComp hour]) ||
			([nowComp hour] == [toComp hour] && [nowComp minute] > [toComp minute]) ||
			([nowComp hour] == [fromComp hour] && [nowComp minute] < [fromComp minute])) {
			// We are outside of allowed time range
			timeInRange = NO;
		}
	} else {
		// Time range doesn't cross midnight (e.g. 4 AM to 5 PM)
		if (([nowComp hour] > [toComp hour] && [nowComp hour] < [fromComp hour]) ||
			([nowComp hour] == [toComp hour] && [nowComp minute] > [toComp minute]) ||
			([nowComp hour] == [fromComp hour] && [nowComp minute] < [fromComp minute])) {
			// We are outside of allowed time range
			timeInRange = NO;
		}
	}
	
	return timeInRange;
}

@end
