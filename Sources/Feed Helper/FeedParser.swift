import Foundation


private extension XMLNode {
  subscript(xPath: String) -> String? {
    return (try? nodes(forXPath: xPath))?.last?.stringValue
  }
}


private extension Episode {
  /// Try to initialize an episode with the data found in an RSS "item" element
  init?(itemNode: XMLNode) {
    // Get the .torrent URL or magnet link
    guard let urlString = itemNode["enclosure/@url"] else {
      NSLog("Missing feed item URL")
      return nil
    }
    
    guard let url = URL(string: urlString) else {
      NSLog("Invalid feed item URL: \(urlString)")
      return nil
    }
    
    // Get the title (includes show name and season/episode numbers)
    guard let title = itemNode["title"], title != "" else {
      NSLog("Missing or empty feed item title")
      return nil
    }
    
    // Get the optional show name from the generic "tv:" namespace
    let showName = itemNode["tv:show_name"]
    
    self.url = url
    self.title = title
    self.showName = showName
  }
}


/// Parses episodes out of a broadcatching RSS feed.
/// Supports additional data specified with the `tv` namespace.
enum FeedParser {
  static func parse(feed: Data) throws -> [Episode] {
    NSLog("Parsing feed")
    
    // Parse xml
    let xml = try XMLDocument(data: feed, options: 0)
    
    // Extract feed item nodes
    let itemNodes = try xml.nodes(forXPath: "//rss/channel/item")
    
    // Extract episodes from NSXMLNodes
    let episodes = itemNodes.flatMap(Episode.init(itemNode:))
    
    NSLog("Parsed \(episodes.count) episodes")
    
    return episodes
  }
}
