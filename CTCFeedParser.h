#import <Foundation/Foundation.h>


@interface CTCFeedParser : NSObject

+ (NSArray<NSDictionary *> *)parseFiles:(NSXMLDocument *)feed
                 error:(NSError * __autoreleasing *)error;

@end
