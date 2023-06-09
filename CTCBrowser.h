#import <Foundation/Foundation.h>


@interface CTCBrowser : NSObject

+ (void)openInBackgroundURL:(NSURL *)url;

+ (void)openInBackgroundFile:(NSString *)file;

@end
