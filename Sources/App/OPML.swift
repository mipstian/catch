import Foundation
import os


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
      os_log("Missing feed URL", log: .main, type: .info)
      return nil
    }
    
    guard let url = URL(string: urlString) else {
      os_log("Invalid feed URL: %{public}@", log: .main, type: .info, urlString)
      return nil
    }
    
    // Get the name
    guard let name = itemNode["@title"] ?? itemNode["@text"], name != "" else {
      os_log("Missing or empty feed title", log: .main, type: .info)
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
    os_log("Parsing OPML file", log: .main, type: .info)
    
    // Parse xml
    let xml = try XMLDocument(data: opml)
    
    // Extract feed item nodes
    let outlineNodes = try xml.nodes(forXPath: "//opml/body//outline")
    
    // Extract episodes from NSXMLNodes
    let feeds = outlineNodes.compactMap(Feed.init(itemNode:))
    
    os_log("Parsed %d feeds", log: .main, type: .info, feeds.count)
    
    return feeds
  }
}

// Creates an OPML file from feeds.
struct OPMLSerializer {
  func serialize(feeds: [Feed]) throws -> Data {
    os_log("Serializing OPML file", log: .main, type: .info)
    
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
