#import "CTCLoginItems.h"


@implementation CTCLoginItems

+ (void)toggleRegisteredAsLoginItem:(BOOL)shouldRegister {
    if (shouldRegister) NSLog(@"Adding app to login items");
	else NSLog(@"Removing app from login items");
	
	// Code totally ripped off from:
	// http://cocoatutorial.grapewave.com/2010/02/creating-andor-removing-a-login-item/
	
	NSString *appPath = NSBundle.mainBundle.bundlePath;
	CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:appPath];
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	
	if (!loginItems) {
		NSLog(@"Couldn't add/remove app to the login items :(");
		return;
	}
	
	if (shouldRegister) {
		// Add Catch to the login items
		LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItems,kLSSharedFileListItemLast, NULL, NULL, url, NULL, NULL);
		if (item) {
			CFRelease(item);
		}
	} else {
		// Remove Catch from the login items
		UInt32 seedValue;
		NSArray *loginItemsArray = (NSArray *)CFBridgingRelease(LSSharedFileListCopySnapshot(loginItems, &seedValue));
        
		for(NSUInteger i = 0; i < loginItemsArray.count; i++) {
			LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)[loginItemsArray objectAtIndex:i];
			// Resolve the item with URL
			if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*)&url, NULL) == noErr) {
				NSString *urlPath = [(__bridge NSURL*)url path];
				if ([urlPath compare:appPath] == NSOrderedSame){
					// Here I am. Remove me please.
					LSSharedFileListItemRemove(loginItems,itemRef);
				}
                CFRelease(url);
			}
		}
	}
    
	CFRelease(loginItems);
}

@end
