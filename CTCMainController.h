#import <Foundation/Foundation.h>
#import "CTCAppDelegate.h"
#import "Preferences.h"


@interface CTCMainController : NSObject <NSUserNotificationCenterDelegate>

- (void)forceCheck;

/* Show the Preferences window */
- (IBAction)showPreferences:(id)sender;

/* Set GUI widgets to reflect status */
- (void)setLastUpdateStatus:(BOOL)lastUpdateWasSuccessful time:(NSDate *)time;
- (void)refreshRecent:(NSArray *)recentTorrentNames;

@end
