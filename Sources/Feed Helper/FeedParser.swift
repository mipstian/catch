import Foundation
import os


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
      os_log("Missing feed item URL", log: .helper, type: .info)
      return nil
    }
    
    guard let url = URL(string: urlString) else {
      os_log("Invalid feed item URL: %{public}@", log: .helper, type: .info, urlString)
      return nil
    }
    
    // Get the title (includes show name and season/episode numbers)
    guard let title = itemNode["title"], title != "" else {
      os_log("Missing or empty feed item title", log: .helper, type: .info)
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
    os_log("Parsing feed...", log: .helper, type: .info)
    
    // Parse xml
    let xml = try XMLDocument(data: feedContents)
    
    // Extract feed item nodes
    let rssItemNodes = try xml.nodes(forXPath: "//rss/channel/item")
    let atomItemNodes = try xml.nodes(forXPath: "//feed/entry")
    let itemNodes = rssItemNodes + atomItemNodes
    
    // Extract episodes from NSXMLNodes
    let episodes = itemNodes.compactMap { Episode(itemNode: $0, feed: feed) }
    
    os_log("Parsed %d episodes", log: .helper, type: .info, episodes.count)
    
    return episodes
  }
}
