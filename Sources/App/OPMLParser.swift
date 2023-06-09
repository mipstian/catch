import Foundation


private extension XMLNode {
  subscript(xPath: String) -> String? {
    return (try? nodes(forXPath: xPath))?.last?.stringValue
  }
}


private extension Feed {
  /// Try to initialize an episode with the data found in an RSS "item" or Atom "entry" element
  init?(itemNode: XMLNode) {
    // Get the item URL
    guard let urlString = itemNode["@xmlUrl"] else {
      NSLog("Missing feed URL")
      return nil
    }
    
    guard let url = URL(string: urlString) else {
      NSLog("Invalid feed URL: \(urlString)")
      return nil
    }
    
    // Get the name
    guard let name = itemNode["@title"], name != "" else {
      NSLog("Missing or empty feed  title")
      return nil
    }
    
    self.name = name
    self.url = url
  }
}

// Parses feeds out of an OPML file.
enum OPMLParser {
  static func parse(opml: Data) throws -> [Feed] {
    NSLog("Parsing OPML file")
    
    // Parse xml
    let xml = try XMLDocument(data: opml)
    
    // Extract feed item nodes
    let outlineNodes = try xml.nodes(forXPath: "//opml/body//outline")
    
    // Extract episodes from NSXMLNodes
    let feeds = outlineNodes.compactMap(Feed.init(itemNode:))
    
    NSLog("Parsed \(feeds.count) feeds")
    
    return feeds
  }
}
