import Foundation


protocol FeedHelperProxyDelegate: class {
  func feedHelperConnectionWasInterrupted()
}


/// Encapsulates an XPC connection to the Feed Helper service, and handles
/// serialization/deserialization.
final class FeedHelperProxy {
  weak var delegate: FeedHelperProxyDelegate? = nil
  
  private let feedHelperConnection = NSXPCConnection(
    serviceName: "com.giorgiocalderolla.Catch.CatchFeedHelper"
  )
  
  private var service: FeedHelperService {
    return feedHelperConnection.remoteObjectProxy as! FeedHelperService
  }
  
  init() {
    // Connect to the feed helper XPC service. Messages will be delivered serially.
    feedHelperConnection.remoteObjectInterface = NSXPCInterface(with: FeedHelperService.self)
    feedHelperConnection.interruptionHandler = { [weak self] in
      DispatchQueue.main.async {
        self?.delegate?.feedHelperConnectionWasInterrupted()
      }
    }
    feedHelperConnection.resume()
  }
  
  deinit {
    feedHelperConnection.invalidate()
  }
  
  func checkFeed(
    url: URL,
    downloadOptions: DownloadOptions,
    previouslyDownloadedURLs: [URL],
    completion: @escaping (Result<[[AnyHashable:Any]]>) -> Void) {
    service.checkFeed(
      url: url,
      downloadingToBookmark: downloadOptions.containerDirectoryBookmark,
      organizingByShow: downloadOptions.shouldOrganizeByShow,
      savingMagnetLinks: downloadOptions.shouldSaveMagnetLinks,
      skippingURLs: previouslyDownloadedURLs.map { $0.absoluteString },
      withReply: { downloadedFeedFiles, error in
        DispatchQueue.main.async {
          if let downloadedFeedFiles = downloadedFeedFiles {
            completion(.success(downloadedFeedFiles))
          } else if let error = error {
            completion(.failure(error))
          } else {
            fatalError("Bad service reply")
          }
        }
      }
    )
  }
  
  func download(
    historyItem: HistoryItem,
    downloadOptions: DownloadOptions,
    completion: @escaping (Result<[AnyHashable:Any]>) -> Void) {
    service.download(
      episode: historyItem.dictionaryRepresentation,
      toBookmark: downloadOptions.containerDirectoryBookmark,
      organizingByShow: downloadOptions.shouldOrganizeByShow,
      savingMagnetLinks: downloadOptions.shouldSaveMagnetLinks,
      withReply: { downloadedFile, error in
        DispatchQueue.main.async {
          if let downloadedFile = downloadedFile {
            completion(.success(downloadedFile))
          } else if let error = error {
            completion(.failure(error))
          } else {
            fatalError("Bad service reply")
          }
        }
      }
    )
  }
}
