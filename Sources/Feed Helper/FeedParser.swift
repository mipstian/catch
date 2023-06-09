import Foundation


private extension XMLNode {
  subscript(xPath: String) -> String? {
    return (try? nodes(forXPath: xPath))?.last?.stringValue
  }
}


private extension Episode {
  /// Try to initialize an episode with the data found in an RSS "item" or Atom "entry" element
  init?(itemNode: XMLNode, feed: Feed) {
    // Get the .torrent URL or magnet link
    guard let urlString = itemNode["enclosure/@url"] ?? itemNode["link/@href"] ?? itemNode["link"] else {
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
    self.feed = feed
  }
}


/// Parses episodes out of a broadcatching RSS or Atom feed.
/// Supports additional data specified with the `tv` namespace.
enum FeedParser {
  static func parse(feed: Feed, feedContents: Data) throws -> [Episode] {
    NSLog("Parsing feed")
    
    // Parse xml
    let xml = try XMLDocument(data: feedContents)
    
    // Extract feed item nodes
    let rssItemNodes = try xml.nodes(forXPath: "//rss/channel/item")
    let atomItemNodes = try xml.nodes(forXPath: "//feed/entry")
    let itemNodes = rssItemNodes + atomItemNodes
    
    // Extract episodes from NSXMLNodes
    let episodes = itemNodes.compactMap { Episode(itemNode: $0, feed: feed) }
    
    NSLog("Parsed \(episodes.count) episodes")
    
    return episodes
  }
}
