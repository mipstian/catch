import Foundation


extension URL {
  var isShowRSSFeed: Bool {
    return host?.hasSuffix("showrss.info") ?? false
  }
  
  var hasShowRSSNamespacesFlag: Bool {
    guard let query = query else { return false }
    return query.contains("namespaces=true")
  }
  
  var isValidFeedURL: Bool {
    guard
      let scheme = scheme
      else {
        return false
    }
    
    guard ["http", "https"].contains(scheme) else {
      NSLog("Bad scheme in feed URL: \(scheme)")
      return false
    }
    
    if isShowRSSFeed && !hasShowRSSNamespacesFlag {
      NSLog("Feed URL does not have namespaces enabled")
      return false
    }
    
    return true
  }
}
