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
    guard let name = itemNode["@title"] ?? itemNode["@text"], name != "" else {
      NSLog("Missing or empty feed title")
      return nil
    }
    
    self.name = name
    self.url = url
  }
  
  var outlineElement: XMLElement {
    let outlineElement = XMLElement(name: "outline")
    
    let titleAttribute = XMLNode(kind: .attribute)
    titleAttribute.name = "title"
    titleAttribute.stringValue = name
    
    let textAttribute = XMLNode(kind: .attribute)
    textAttribute.name = "text"
    textAttribute.stringValue = name
    
    let typeAttribute = XMLNode(kind: .attribute)
    typeAttribute.name = "type"
    typeAttribute.stringValue = "rss"
    
    let xmlURLAttribute = XMLNode(kind: .attribute)
    xmlURLAttribute.name = "xmlUrl"
    xmlURLAttribute.stringValue = url.absoluteString
    
    outlineElement.addAttribute(titleAttribute)
    outlineElement.addAttribute(textAttribute)
    outlineElement.addAttribute(typeAttribute)
    outlineElement.addAttribute(xmlURLAttribute)
    
    return outlineElement
  }
}

// Parses feeds out of an OPML file.
struct OPMLParser {
  func parse(opml: Data) throws -> [Feed] {
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

// Creates an OPML file from feeds.
struct OPMLSerializer {
  func serialize(feeds: [Feed]) throws -> Data {
    NSLog("Serializing OPML file")
    
    let xml = XMLDocument()
    xml.characterEncoding = "utf-8"
    
    let opmlElement = XMLElement(name: "opml")
    
    let headElement = XMLElement(name: "head")
    let bodyElement = XMLElement(name: "body")
    
    let outlineElements = feeds.map(\.outlineElement)
    for outlineElement in outlineElements {
      bodyElement.addChild(outlineElement)
    }
    
    opmlElement.addChild(headElement)
    opmlElement.addChild(bodyElement)
    
    xml.addChild(opmlElement)

    return xml.xmlData(options: [.nodeCompactEmptyElement, .nodePrettyPrint])
  }
}
