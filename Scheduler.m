//
//  FeedChecker.m
//  Catch
//
//  Created by Giorgio Calderolla on 6/12/10.
//  Copyright 2010 n\a. All rights reserved.
//

#import "Scheduler.h"
#import "Catch.h"
#import "CTCFeedChecker.h"


@interface Scheduler ()

@property (strong, nonatomic) NSTimer* repeatingTimer;
@property (strong, nonatomic) NSXPCConnection *feedCheckerConnection;
@property (assign, nonatomic, getter = isActive) BOOL active;
@property (assign, nonatomic, getter = isRunning) BOOL running;

@end


@implementation Scheduler

- (id)init {
	self.active = YES;
	self.running = NO;
    
    // Create a single connection to the feed helper
    // Messages will be delivered serially
    self.feedCheckerConnection = [[NSXPCConnection alloc] initWithServiceName:@"com.giorgiocalderolla.Catch.CatchFeedHelper"];
    self.feedCheckerConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(CTCFeedCheck)];
    [self.feedCheckerConnection resume];
	
	// Create a timer to check periodically
    self.repeatingTimer = [NSTimer scheduledTimerWithTimeInterval:FEED_UPDATE_INTERVAL
														   target:self
														 selector:@selector(tick:)
														 userInfo:nil
														  repeats:YES];
	
	return self;
}

- (void)callFeedCheckerWithReplyHandler:(CTCFeedCheckCompletionHandler)replyHandler {
    // Read configuration
    NSURL *feedURL = [NSURL URLWithString:Preferences.feedURL];
    NSString *downloadPath = [NSUserDefaults.standardUserDefaults stringForKey:PREFERENCE_KEY_SAVE_PATH];
    BOOL organizeByFolder = [NSUserDefaults.standardUserDefaults boolForKey:PREFERENCE_KEY_ORGANIZE_TORRENTS];
    NSArray *previouslyDownloadedURLs = [NSUserDefaults.standardUserDefaults arrayForKey:PREFERENCE_KEY_HISTORY];
    
    // Call feed checker service
    CTCFeedChecker *feedChecker = [self.feedCheckerConnection remoteObjectProxy];
    [feedChecker checkShowRSSFeed:feedURL
                downloadingToPath:downloadPath
               organizingByFolder:organizeByFolder
                     skippingURLs:previouslyDownloadedURLs
                        withReply:replyHandler];
}

- (void)reportStatus {
	NSLog(@"Scheduler: reporting status: active = %d, running = %d", self.isActive, self.isRunning);
	
	// Report status to application delegate
	[[NSApp delegate] schedulerStatusActive:self.isActive running:self.isRunning];
}

- (BOOL)pauseResume {
	self.active = !self.isActive;
	
    [self reportStatus];
	
	return self.active;
}

- (void)forceCheck {
	NSLog(@"Scheduler: forcing check");
    
	// Set the next timer fire date to be ASAP
	[self.repeatingTimer setFireDate:NSDate.distantPast];
}

- (void)tick:(NSTimer*)timer {
	NSLog(@"Scheduler: tick");
	
	if (!self.isActive) {
		NSLog(@"Scheduler: tick skipped, paused");
		return;
	}
	
	// Only work with valid preferences
	if (![Preferences validate]) {
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
	
	self.running = YES;
	
    [self reportStatus];
	
    [self callFeedCheckerWithReplyHandler:^(BOOL wasCheckSuccessful,
                                            NSArray *downloadedFeedFiles){
        self.running = NO;
        [self reportStatus];
        [[NSApp delegate] lastUpdateStatus:wasCheckSuccessful
                                      time:NSDate.date];
    }];
}
			
- (BOOL)checkTime {
	NSDate* now = NSDate.date;
	NSDate* from = (NSDate *)[NSUserDefaults.standardUserDefaults objectForKey:PREFERENCE_KEY_UPDATE_FROM];
	NSDate* to = (NSDate *)[NSUserDefaults.standardUserDefaults objectForKey:PREFERENCE_KEY_UPDATE_TO];
	
	NSCalendar* calendar = NSCalendar.currentCalendar;
	
	// Get minutes and hours from each date
	NSDateComponents* nowComp = [calendar components:NSHourCalendarUnit|NSMinuteCalendarUnit
												   fromDate:now];
	NSDateComponents* fromComp = [calendar components:NSHourCalendarUnit|NSMinuteCalendarUnit
													fromDate:from];
	NSDateComponents* toComp = [calendar components:NSHourCalendarUnit|NSMinuteCalendarUnit
												  fromDate:to];
	
	if (fromComp.hour > toComp.hour ||
		(fromComp.hour == toComp.hour && fromComp.minute > toComp.minute)) {
		// Time range crosses midnight (e.g. 11 PM to 3 AM)
		if ((nowComp.hour > toComp.hour && nowComp.hour < fromComp.hour) ||
			(nowComp.hour == toComp.hour && nowComp.minute > toComp.minute) ||
			(nowComp.hour == fromComp.hour && nowComp.minute < fromComp.minute)) {
			// We are outside of allowed time range
			return NO;
		}
	} else {
		// Time range doesn't cross midnight (e.g. 4 AM to 5 PM)
		if ((nowComp.hour > toComp.hour && nowComp.hour < fromComp.hour) ||
			(nowComp.hour == toComp.hour && nowComp.minute > toComp.minute) ||
			(nowComp.hour == fromComp.hour && nowComp.minute < fromComp.minute)) {
			// We are outside of allowed time range
			return NO;
		}
	}
	
	return YES;
}

@end
