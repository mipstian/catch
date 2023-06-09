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
