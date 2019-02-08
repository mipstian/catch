import Foundation


struct Feed {
  var name: String
  var url: URL
  
  init(name: String, url: URL) {
    self.name = name
    self.url = url
  }
}


// MARK: Serialization
extension Feed {
  var dictionaryRepresentation: [AnyHashable:Any] {
    return [
      "name": name,
      "url": url.absoluteString
    ]
  }
}

// MARK: Deserialization
extension Feed {
  init?(dictionary: [AnyHashable:Any]) {
    guard
      let name = dictionary["name"] as? String,
      let url = (dictionary["url"] as? String).flatMap(URL.init),
      url.isValidFeedURL
    else {
      return nil
    }
    self.name = name
    self.url = url
  }
}
