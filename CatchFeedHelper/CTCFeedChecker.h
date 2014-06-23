#import <Foundation/Foundation.h>


extern NSString *kCTCFeedCheckerErrorDomain;
typedef void (^CTCFeedCheckCompletionHandler)(NSArray *downloadedFeedFiles,
                                              NSError *error);


@protocol CTCFeedCheck

- (void)checkShowRSSFeed:(NSURL *)feedURL
   downloadingToBookmark:(NSData *)downloadFolderBookmark
      organizingByFolder:(BOOL)shouldOrganizeByFolder
            skippingURLs:(NSArray *)previouslyDownloadedURLs
               withReply:(CTCFeedCheckCompletionHandler)reply;

@end


@interface CTCFeedChecker : NSObject <CTCFeedCheck, NSXPCListenerDelegate>

+ (instancetype)sharedChecker;

@end
