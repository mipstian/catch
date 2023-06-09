#import "CTCFeedChecker.h"


@implementation CTCFeedChecker

+ (instancetype)sharedChecker {
    static CTCFeedChecker *sharedChecker = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedChecker = CTCFeedChecker.new;
    });
    
    return sharedChecker;
}

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(CTCFeedCheck)];
    newConnection.exportedObject = self;
    [newConnection resume];
    
    return YES;
}

- (void)checkShowRSSFeed:(NSURL *)feedURL
       downloadingToPath:(NSString *)downloadFolderPath
      organizingByFolder:(BOOL)shouldOrganizeByFolder
            skippingURLs:(NSArray *)previouslyDownloadedURLs
               withReply:(void (^)(NSError *))reply {
    NSLog(@"Checker running");
    reply(nil);
}

@end
