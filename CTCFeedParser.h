#import <Foundation/Foundation.h>


@interface CTCFeedParser : NSObject

+ (NSArray*)parseURLs:(NSXMLDocument*)feed;

+ (NSArray*)parseFolders:(NSXMLDocument*)feed;

@end
