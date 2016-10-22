import Foundation


private extension XMLNode {
  subscript(xPath: String) -> String? {
    return (try? nodes(forXPath: xPath))?.last?.stringValue
  }
}


public class FeedParser: NSObject {
  public typealias FeedItem = [String:String]
  
  public static func parse(feed: XMLDocument) throws -> [FeedItem] {
    NSLog("Parsing feed")
    
    // Extract feed items
    let itemNodes = try feed.nodes(forXPath: "//rss/channel/item")
    
    // Extract files from NSXMLNodes
    let items = itemNodes.flatMap { itemNode -> FeedItem? in
      // Get the .torrent URL or magnet link
      guard let urlString = itemNode["enclosure/@url"] else {
        NSLog("Missing feed item URL")
        return nil
      }
      
      guard URL(string: urlString) != nil else {
        NSLog("Invalid feed item URL: \(urlString)")
        return nil
      }
      
      // Get the title (includes show name and season/episode numbers)
      guard let title = itemNode["title"], title != "" else {
        NSLog("Missing or empty feed item title")
        return nil
      }
      
      var item = ["title": title, "url": urlString]
      
      // Get the show name from the generic "tv:" namespace, fallback to the old "showrss:" namespace
      // This field is optional
      if let showName = itemNode["tv:show_name"] ?? itemNode["showrss:showname"] {
        item["showName"] = showName
      }
      
      return item
    }
    
    NSLog("Parsed \(itemNodes.count) files")
    
    return items
  }
}
