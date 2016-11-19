import Foundation


protocol FeedHelperProxyDelegate: class {
  func feedHelperConnectionWasInterrupted()
}


final class FeedHelperProxy {
  weak var delegate: FeedHelperProxyDelegate? = nil
  
  private static let xpcServiceName = "com.giorgiocalderolla.Catch.CatchFeedHelper"
  
  private let feedHelperConnection = NSXPCConnection(serviceName: xpcServiceName)
  
  private var service: FeedHelperService {
    return feedHelperConnection.remoteObjectProxy as! FeedHelperService
  }
  
  init() {
    // Create and start single connection to the feed helper
    // Messages will be delivered serially
    feedHelperConnection.remoteObjectInterface = NSXPCInterface(with: FeedHelperService.self)
    feedHelperConnection.interruptionHandler = {
      DispatchQueue.main.async { [weak self] in
        self?.delegate?.feedHelperConnectionWasInterrupted()
      }
    }
    feedHelperConnection.resume()
  }
  
  func checkFeed(
    _ feedURL: URL,
    downloadOptions: DownloadOptions,
    previouslyDownloadedURLs: [URL],
    completion: @escaping FeedHelperService.FeedCheckReply) {
    service.checkShowRSSFeed(
      feedURL: feedURL,
      downloadingToBookmark: downloadOptions.containerDirectoryBookmark,
      organizingByShow: downloadOptions.shouldOrganizeByShow,
      savingMagnetLinks: downloadOptions.shouldSaveMagnetLinks,
      skippingURLs: previouslyDownloadedURLs.map { $0.absoluteString },
      withReply: { downloadedFeedFiles, error in
        DispatchQueue.main.async {
          completion(downloadedFeedFiles, error)
        }
      }
    )
  }
  
  func downloadHistoryItem(
    _ historyItem: HistoryItem,
    downloadOptions: DownloadOptions,
    completion: @escaping FeedHelperService.FileDownloadReply) {
    service.downloadFile(
      file: historyItem.dictionaryRepresentation,
      toBookmark: downloadOptions.containerDirectoryBookmark,
      organizingByShow: downloadOptions.shouldOrganizeByShow,
      savingMagnetLinks: downloadOptions.shouldSaveMagnetLinks,
      withReply: { downloadedFile, error in
        DispatchQueue.main.async {
          completion(downloadedFile, error)
        }
      }
    )
  }
}
