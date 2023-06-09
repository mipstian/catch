import Foundation


extension String {
  private static let torrentFileExtension = ".torrent"
  private static let weblocFileExtension = ".webloc"
  
  var sanitizedForFileSystem: String {
    return replacingOccurrences(of: "/", with: "").trimmingCharacters(in: .whitespaces)
  }
  
  private func with(fileExtension: String) -> String {
    return hasSuffix(fileExtension) ? self : self + fileExtension
  }
  
  var torrentFileName: String {
    return sanitizedForFileSystem.with(fileExtension: .torrentFileExtension)
  }
  
  var weblocFileName: String {
    return sanitizedForFileSystem.with(fileExtension: .weblocFileExtension)
  }
}


extension FileManager {
  var homeDirectory: String {
    return NSHomeDirectory()
  }
  
  var downloadsDirectory: String? {
    return NSSearchPathForDirectoriesInDomains(.downloadsDirectory, .userDomainMask, true).first
  }
}


extension URL {
  var suggestedDownloadFileName: String? {
    return pathComponents.last?.removingPercentEncoding
  }
}
