#import "CTCFeedParser.h"


@implementation CTCFeedParser

+ (NSArray*)parseFiles:(NSXMLDocument*)feed
                 error:(NSError * __autoreleasing *)outError {
    NSLog(@"Parsing feed");
    
    NSError *error = nil;
    
    // Get files with XPath
    NSArray *fileNodes = [feed nodesForXPath:@"//rss/channel/item" error:&error];
    
    if (!fileNodes) {
        *outError = error;
        return nil;
    }
    
    // Extract files from NSXMLNodes
    NSMutableArray *feedFiles = [NSMutableArray arrayWithCapacity:fileNodes.count];
    
    for(NSXMLNode *fileNode in fileNodes) {
        // Get the .torrent URL or magnet link
        NSString *url = [[[fileNode nodesForXPath:@"enclosure/@url" error:&error] lastObject] stringValue];
        
        // Get the title (includes show name and season/episode numbers)
        NSString *title = [[[fileNode nodesForXPath:@"title" error:&error] lastObject] stringValue];
        
        // Get the show name from the generic "tv:" namespace, fallback to the old "showrss:" namespace
        NSString *showName = [[[fileNode nodesForXPath:@"tv:show_name" error:&error] lastObject] stringValue];
        if (!showName) {
            showName = [[[fileNode nodesForXPath:@"showrss:showname" error:&error] lastObject] stringValue];
        }
        
        [feedFiles addObject:@{@"title": title,
                               @"url": url,
                               @"showName": showName ?: NSNull.null}];
    }
    
    NSLog(@"Parsed %lu files", (unsigned long)fileNodes.count);
    
    return feedFiles;
}

@end
