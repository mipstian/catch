#import "CTCFeedParser.h"


@implementation CTCFeedParser

+ (NSArray*)parseURLs:(NSXMLDocument*)feed {
	NSLog(@"CTCFeedParser: parsing feed for URLs");
	
	NSError* error = nil;
	
	// Get file URLs with XPath
	NSArray* fileNodes = [feed nodesForXPath:@"//rss/channel/item" error:&error];
	NSLog(@"File Nodes:	 %@", fileNodes);
	
	if (fileNodes) {
		NSLog(@"CTCFeedParser: got %lu files", (unsigned long)fileNodes.count);
	} else {
		NSLog(@"CTCFeedParser: parsing for URLs failed: %@", error);
		return nil;
	}
	
	// Extract URLs from NSXMLNodes
	NSMutableArray* fileURLs = [NSMutableArray arrayWithCapacity:fileNodes.count];
	
	for(NSXMLNode* file in fileNodes) {
		NSString* url = [[[file nodesForXPath:@"enclosure/@url" error:&error] lastObject] stringValue];
		NSString* title = [[[file nodesForXPath:@"title" error:&error] lastObject] stringValue];
		NSLog(@"CTCFeedParser: got file: %@ at %@", title, url);
		[fileURLs addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							 title, @"title", url, @"url", nil]];
	}
	
	return fileURLs;
}

+ (NSArray*)parseFolders:(NSXMLDocument*)feed {
	NSLog(@"CTCFeedParser: parsing feed for folders");
	
	NSError* error = nil;
	
	// Get file folders with XPath
	NSArray* folderNodes = [feed nodesForXPath:@"//rss/channel/item/showrss:showname" error:&error];
	
	if (folderNodes) {
		NSLog(@"CTCFeedParser: got %lu folders", (unsigned long)folderNodes.count);
	} else {
		NSLog(@"CTCFeedParser: parsing for folders failed: %@", error);
		return nil;
	}
	
	// Extract folders from NSXMLNodes
	NSMutableArray* fileFolders = [NSMutableArray arrayWithCapacity:folderNodes.count];
	
	for(NSXMLNode* node in folderNodes) {
		NSString* folder = [node stringValue];
		folder = [folder stringByReplacingOccurrencesOfString:@"/" withString:@""]; // Strip slashes
		folder = [folder stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]; // Trim whitespace
		[fileFolders addObject:folder];
	}
	
	NSLog(@"CTCFeedParser: got folders:\n%@", fileFolders);
	
	return fileFolders;
}

@end
