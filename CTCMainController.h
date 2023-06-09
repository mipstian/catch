#import <Foundation/Foundation.h>
#import "CTCAppDelegate.h"
#import "Preferences.h"


@interface CTCMainController : NSObject <NSUserNotificationCenterDelegate>

- (void)forceCheck;

/* Show the Preferences window */
- (IBAction)showPreferences:(id)sender;

@end
