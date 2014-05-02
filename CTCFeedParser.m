#import "CTCFeedParser.h"


@implementation CTCFeedParser

+ (NSArray*)parseURLs:(NSXMLDocument*)feed {
	NSLog(@"Parsing feed for URLs");
	
	NSError *error = nil;
	
	// Get file URLs with XPath
	NSArray *fileNodes = [feed nodesForXPath:@"//rss/channel/item" error:&error];
	
    if (!fileNodes) {
        NSLog(@"Parsing for URLs failed: %@", error);
		return nil;
    }
    
    NSLog(@"Parsed %lu files", (unsigned long)fileNodes.count);
	
	// Extract URLs from NSXMLNodes
	NSMutableArray *feedFiles = [NSMutableArray arrayWithCapacity:fileNodes.count];
	
	for(NSXMLNode *file in fileNodes) {
		NSString *url = [[[file nodesForXPath:@"enclosure/@url" error:&error] lastObject] stringValue];
		NSString *title = [[[file nodesForXPath:@"title" error:&error] lastObject] stringValue];
		[feedFiles addObject:@{@"title": title,
                               @"url": url}];
	}
    
    NSLog(@"Parsed files: %@", feedFiles);
	
	return feedFiles;
}

+ (NSArray*)parseFolders:(NSXMLDocument*)feed {
	NSLog(@"Parsing feed for folders");
	
	NSError *error = nil;
	
	// Get file folders with XPath
	NSArray *folderNodes = [feed nodesForXPath:@"//rss/channel/item/showrss:showname" error:&error];
	
	if (folderNodes) {
		NSLog(@"Parsed %lu folders", (unsigned long)folderNodes.count);
	} else {
		NSLog(@"Parsing for folders failed: %@", error);
		return nil;
	}
	
	// Extract folders from NSXMLNodes
	NSMutableArray *fileFolders = [NSMutableArray arrayWithCapacity:folderNodes.count];
	
	for(NSXMLNode *node in folderNodes) {
		NSString *folder = [node stringValue];
		folder = [folder stringByReplacingOccurrencesOfString:@"/" withString:@""]; // Strip slashes
		folder = [folder stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]; // Trim whitespace
		[fileFolders addObject:folder];
	}
	
	NSLog(@"Parsed folders:\n%@", fileFolders);
	
	return fileFolders;
}

@end
