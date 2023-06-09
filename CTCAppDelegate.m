#import "CTCAppDelegate.h"
#import "CTCMenuController.h"
#import "CTCPreferencesController.h"
#import "CTCDefaults.h"
#import "CTCScheduler.h"


@interface CTCAppDelegate ()
@property (strong, nonatomic) id<NSObject> activityToken;
@end


@implementation CTCAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Set default values for defaults
	[CTCDefaults setDefaultDefaults];
    
	// Enable Notification Center notifications
    [NSUserNotificationCenter.defaultUserNotificationCenter setDelegate:self];
    
    // Make sure we can keep running in the background if the system supports App Nap
    if ([NSProcessInfo.processInfo respondsToSelector:@selector(beginActivityWithOptions:reason:)]) {
        self.activityToken = [NSProcessInfo.processInfo
                              beginActivityWithOptions:NSActivityIdleSystemSleepDisabled|NSActivitySuddenTerminationDisabled
                              reason:@"Background checking is the whole point of the app"];
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Save defaults
	[CTCDefaults save];
    
    // Stop preventing App Nap. Not that it matters at this point, but
    // we should remember to do this in case we move to only running the
    // scheduler when needed, instead of all the time.
    if ([NSProcessInfo.processInfo respondsToSelector:@selector(beginActivityWithOptions:reason:)]) {
        [NSProcessInfo.processInfo endActivity:self.activityToken];
    }
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
	 shouldPresentNotification:(NSUserNotification *)notification {
	return YES;
}

@end
