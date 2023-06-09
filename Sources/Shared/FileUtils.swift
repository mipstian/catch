import Foundation


private extension String {
  static let torrentFileExtension = ".torrent"
  static let weblocFileExtension = ".webloc"
}


enum FileUtils {
  static var userDownloadsDirectory: String? {
    return NSSearchPathForDirectoriesInDomains(.downloadsDirectory, .userDomainMask, true).first
  }
  
  static var userHomeDirectory: String {
    return NSHomeDirectory()
  }
  
  static func bookmark(for url: URL) throws -> Data {
    return try url.bookmarkData(options: .minimalBookmark)
  }
  
  static func url(from bookmark: Data) throws -> URL {
    var isStale = false
    let url: URL
    
    do {
      // TODO: figure out why this init is optional, which contradicts the docs
      url = try URL(resolvingBookmarkData: bookmark, bookmarkDataIsStale: &isStale)!
    } catch {
      NSLog("Could not get URL from bookmark: \(error)")
      throw error
    }
    
    return url
  }
  
  static func filename(from fileURL: URL) -> String {
    // Compute destination filename
    let filename = fileURL.pathComponents.last!
    
    // Reverse urlencode
    return filename.removingPercentEncoding!
  }
  
  static func fileName(from string: String) -> String {
    return string
      .replacingOccurrences(of: "/", with: "")
      .trimmingCharacters(in: .whitespaces)
  }
  
  private static func fileName(from string: String, fileExtension: String) -> String {
    let cleanName = fileName(from: string)
    
    let hasExtension = cleanName.hasSuffix(fileExtension)
    
    // Add extension if needed
    return hasExtension ? cleanName : cleanName + fileExtension
  }
  
  static func torrentFilename(from string: String) -> String {
    return fileName(from: string, fileExtension: .torrentFileExtension)
  }
  
  static func magnetFilename(from string: String) -> String {
    return fileName(from: string, fileExtension: .weblocFileExtension)
  }
}
