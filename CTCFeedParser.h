#import <Foundation/Foundation.h>


@interface CTCFeedParser : NSObject

+ (NSArray*)parseFiles:(NSXMLDocument*)feed
                 error:(NSError * __autoreleasing *)error;

@end
