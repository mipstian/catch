import Foundation


// In a sandboxed environment, URL bookmarks can be passed from an app to an unpriviledged
// XPC service in order to allow it access to a filesystem location. Catch uses this mechanism
// to transfer the main app's access to the download directory (granted by the user via powerbox)
// to the feed helper service.


extension Data {
  static func sandboxBookmark(for url: URL) throws -> Data {
    return try url.bookmarkData(options: .minimalBookmark)
  }
}


extension URL {
  init(sandboxBookmark: Data) throws {
    var isStale = false
    
    do {
      self = try URL(resolvingBookmarkData: sandboxBookmark, bookmarkDataIsStale: &isStale)
    } catch {
      NSLog("Could not get URL from bookmark: \(error)")
      throw error
    }
  }
}
