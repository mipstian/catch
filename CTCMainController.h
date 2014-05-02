#import <Foundation/Foundation.h>
#import "CTCAppDelegate.h"
#import "Preferences.h"


@interface CTCMainController : NSObject <NSUserNotificationCenterDelegate>

/* Show the Preferences window */
- (IBAction)showPreferences:(id)sender;

/* Set GUI widgets to reflect status */
- (void)setStatusActive:(BOOL)isActive running:(BOOL)isRunning;
- (void)setLastUpdateStatus:(BOOL)lastUpdateWasSuccessful time:(NSDate *)time;
- (void)refreshRecent:(NSArray *)recentTorrentNames;

/* Notifications */
- (void)torrentNotificationWithDescription:(NSString *)description;

@end
