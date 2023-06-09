import Foundation


/// Implements the FeedHelperService XPC protocol, and handles serialization/deserialization
final class Service: NSObject {
  static let shared = Service()
  
  private override init() {}
}


extension Service: FeedHelperService {
  func checkShowRSSFeed(
    feedURL: URL,
    downloadingToBookmark downloadDirectoryBookmark: Data,
    organizingByShow shouldOrganizeByShow: Bool,
    savingMagnetLinks shouldSaveMagnetLinks: Bool,
    skippingURLs previouslyDownloadedURLs: [String],
    withReply reply: (_ downloadedFeedFiles: [[AnyHashable:Any]]?, _ error: Error?) -> Void) {
    let downloadedFeedFiles: [[AnyHashable:Any]]
    
    do {
      let downloadOptions = try DownloadOptions(
        containerDirectoryBookmark: downloadDirectoryBookmark,
        shouldOrganizeByShow: shouldOrganizeByShow,
        shouldSaveMagnetLinks: shouldSaveMagnetLinks
      )
      
      downloadedFeedFiles = try FeedHelper.checkShowRSSFeed(
        feedURL: feedURL,
        downloadOptions: downloadOptions,
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
    toBookmark downloadDirectoryBookmark: Data,
    organizingByShow shouldOrganizeByShow: Bool,
    savingMagnetLinks shouldSaveMagnetLinks: Bool,
    withReply reply: (_ downloadedFile: [AnyHashable:Any]?, _ error: Error?) -> Void) {
    let downloadedFile: [AnyHashable:Any]?
    
    do {
      let downloadOptions = try DownloadOptions(
        containerDirectoryBookmark: downloadDirectoryBookmark,
        shouldOrganizeByShow: shouldOrganizeByShow,
        shouldSaveMagnetLinks: shouldSaveMagnetLinks
      )
      
      downloadedFile = try FeedHelper.downloadFile(file: file, downloadOptions: downloadOptions)
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
