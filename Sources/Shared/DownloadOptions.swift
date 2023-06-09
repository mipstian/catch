import Foundation


struct DownloadOptions {
  let containerDirectory: URL
  let shouldOrganizeByShow: Bool
  let shouldSaveMagnetLinks: Bool
}


// Serialization
extension DownloadOptions {
  var containerDirectoryBookmark: Data {
    // Create a bookmark so we can transfer access to the downloads path
    // to the feed helper service
    return try! FileUtils.bookmark(for: containerDirectory)
  }
}


// Deserialization
extension DownloadOptions {
  init(containerDirectoryBookmark: Data, shouldOrganizeByShow: Bool, shouldSaveMagnetLinks: Bool) throws {
    // Resolve the bookmark that the main app gives us to transfer access to
    // the download directory
    containerDirectory = try FileUtils.url(from: containerDirectoryBookmark)
    
    self.shouldOrganizeByShow = shouldOrganizeByShow
    self.shouldSaveMagnetLinks = shouldSaveMagnetLinks
  }
}
