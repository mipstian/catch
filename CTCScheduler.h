#import <Cocoa/Cocoa.h>
#import "Preferences.h"


@interface CTCScheduler : NSObject

- (BOOL)pauseResume;

- (void)forceCheck;

@end
