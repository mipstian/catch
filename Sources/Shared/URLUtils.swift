import Foundation
import os


extension URL {
  var isShowRSSFeed: Bool {
    return host?.hasSuffix("showrss.info") ?? false
  }
  
  var hasShowRSSNamespacesFlag: Bool {
    guard let query = query else { return false }
    return query.contains("namespaces=true")
  }
  
  var isMagnetLink: Bool {
    return scheme == "magnet"
  }
  
  var isValidFeedURL: Bool {
    guard
      let scheme = scheme,
      host != nil
    else {
        return false
    }
    
    guard ["http", "https"].contains(scheme) else {
      os_log("Bad scheme in feed URL: %{public}@", log: .main, type: .info, scheme)
      return false
    }
    
    if isShowRSSFeed && !hasShowRSSNamespacesFlag {
      os_log("Feed URL does not have namespaces enabled", log: .main, type: .info)
      return false
    }
    
    return true
  }
}
