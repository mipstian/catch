#import <Foundation/Foundation.h>


@interface CTCMainController : NSObject <NSUserNotificationCenterDelegate>

- (void)forceCheck;

/* Show the Preferences window */
- (IBAction)showPreferences:(id)sender;

@end
