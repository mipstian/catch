#import "CTCFeedParser.h"


@implementation CTCFeedParser

+ (NSArray*)parseFiles:(NSXMLDocument*)feed {
    NSLog(@"Parsing feed");
    
    NSError *error = nil;
    
    // Get file URLs with XPath
    NSArray *fileNodes = [feed nodesForXPath:@"//rss/channel/item" error:&error];
    
    if (!fileNodes) {
        NSLog(@"Parsing for URLs failed: %@", error);
        return nil;
    }
    
    // Extract URLs from NSXMLNodes
    NSMutableArray *feedFiles = [NSMutableArray arrayWithCapacity:fileNodes.count];
    
    for(NSXMLNode *fileNode in fileNodes) {
        NSString *url = [[[fileNode nodesForXPath:@"enclosure/@url" error:&error] lastObject] stringValue];
        NSString *title = [[[fileNode nodesForXPath:@"title" error:&error] lastObject] stringValue];
        NSString *showName = [[[fileNode nodesForXPath:@"showrss:showname" error:&error] lastObject] stringValue];
        [feedFiles addObject:@{@"title": title,
                               @"url": url,
                               @"showName": showName ?: NSNull.null}];
    }
    
    NSLog(@"Parsed %lu files: %@", (unsigned long)fileNodes.count, feedFiles);
    
    return feedFiles;
}

@end
