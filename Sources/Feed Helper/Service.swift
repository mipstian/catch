import Foundation


/// Implements the FeedHelperService XPC protocol, and handles serialization/deserialization
final class Service: NSObject {
  static let shared = Service()
  
  private override init() {}
}


extension Service: FeedHelperService {
  func checkFeed(
    url: URL,
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
      
      downloadedFeedFiles = try FeedHelper.checkFeed(
        url: url,
        downloadOptions: downloadOptions,
        skippingURLs: previouslyDownloadedURLs.map { URL.init(string: $0)! }
      )
    } catch {
      reply(nil, error)
      return
    }
    
    reply(downloadedFeedFiles, nil)
  }
  
  func download(
    episode: [AnyHashable:Any],
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
      
      downloadedFile = try FeedHelper.download(
        episode: Episode(dictionary: episode)!,
        downloadOptions: downloadOptions
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
