#import <Foundation/Foundation.h>


@interface CTCFeedParser : NSObject

+ (NSArray*)parseFiles:(NSXMLDocument*)feed;

@end
