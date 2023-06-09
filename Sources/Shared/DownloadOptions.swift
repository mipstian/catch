import Foundation


struct DownloadOptions {
  let containerDirectory: URL
  let shouldOrganizeByShow: Bool
  let shouldSaveMagnetLinks: Bool
}


// Serialization
extension DownloadOptions {
  var containerDirectoryBookmark: Data {
    return try! .sandboxBookmark(for: containerDirectory)
  }
}


// Deserialization
extension DownloadOptions {
  init(containerDirectoryBookmark: Data, shouldOrganizeByShow: Bool, shouldSaveMagnetLinks: Bool) throws {
    containerDirectory = try URL(sandboxBookmark: containerDirectoryBookmark)
    
    self.shouldOrganizeByShow = shouldOrganizeByShow
    self.shouldSaveMagnetLinks = shouldSaveMagnetLinks
  }
}
