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
  
  var isTorrentFilePath: Bool {
    return hasSuffix(.torrentFileExtension)
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
  
  var isWritableDirectory: Bool {
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue else {
      // Download path does not exist or is not a directory
      return false
    }
    
    guard FileManager.default.isWritableFile(atPath: path) else {
      // Download path is not writable
      return false
    }
    
    return true
  }
}
