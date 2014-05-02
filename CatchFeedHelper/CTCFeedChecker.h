#import <Foundation/Foundation.h>


typedef void (^CTCFeedCheckCompletionHandler)(BOOL error,
                                              NSArray *downloadedFeedFiles);


@protocol CTCFeedCheck

- (void)checkShowRSSFeed:(NSURL *)feedURL
       downloadingToPath:(NSString *)downloadFolderPath
      organizingByFolder:(BOOL)shouldOrganizeByFolder
            skippingURLs:(NSArray *)previouslyDownloadedURLs
               withReply:(CTCFeedCheckCompletionHandler)reply;

@end


@interface CTCFeedChecker : NSObject <CTCFeedCheck, NSXPCListenerDelegate>

+ (instancetype)sharedChecker;

@end
