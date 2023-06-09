import Foundation


/// Implements the FeedHelperService XPC protocol, and handles
/// serialization/deserialization
final class Service: NSObject {
  static let shared = Service()
  
  private override init() {}
}


extension Service: FeedHelperService {
  func checkShowRSSFeed(
    feedURL: URL,
    downloadingToBookmark downloadFolderBookmark: Data,
    organizingByFolder shouldOrganizeByFolder: Bool,
    savingMagnetLinks shouldSaveMagnetLinks: Bool,
    skippingURLs previouslyDownloadedURLs: [String],
    withReply reply: (_ downloadedFeedFiles: [[AnyHashable:Any]]?, _ error: Error?) -> Void) {
    let downloadedFeedFiles: [[AnyHashable:Any]]
    
    do {
      downloadedFeedFiles = try FeedHelper.checkShowRSSFeed(
        feedURL: feedURL,
        downloadingToBookmark: downloadFolderBookmark,
        organizingByFolder: shouldOrganizeByFolder,
        savingMagnetLinks: shouldSaveMagnetLinks,
        skippingURLs: previouslyDownloadedURLs
      )
    } catch {
      reply(nil, error)
      return
    }
    
    reply(downloadedFeedFiles, nil)
  }
  
  func downloadFile(
    file: [AnyHashable:Any],
    toBookmark downloadFolderBookmark: Data,
    organizingByFolder shouldOrganizeByFolder: Bool,
    savingMagnetLinks shouldSaveMagnetLinks: Bool,
    withReply reply: (_ downloadedFile: [AnyHashable:Any]?, _ error: Error?) -> Void) {
    let downloadedFile: [AnyHashable:Any]?
    
    do {
      downloadedFile = try FeedHelper.downloadFile(
        file: file,
        toBookmark: downloadFolderBookmark,
        organizingByFolder: shouldOrganizeByFolder,
        savingMagnetLinks: shouldSaveMagnetLinks
      )
    } catch {
      reply(nil, error)
      return
    }
    
    reply(downloadedFile, nil)
  }
}


extension Service: NSXPCListenerDelegate {
  func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
    newConnection.exportedInterface = NSXPCInterface(with: FeedHelperService.self)
    newConnection.exportedObject = self
    newConnection.resume()
    
    return true
  }
}
