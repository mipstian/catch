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
  
  func checkFeeds(
    feeds: [Feed],
    downloadOptions: DownloadOptions,
    previouslyDownloadedURLs: [URL],
    completion: @escaping (Result<[DownloadedEpisode], Error>) -> Void) {
    service.checkFeeds(
      feeds: feeds.map { $0.dictionaryRepresentation },
      downloadingToBookmark: downloadOptions.containerDirectoryBookmark,
      organizingByShow: downloadOptions.shouldOrganizeByShow,
      savingMagnetLinks: downloadOptions.shouldSaveMagnetLinks,
      skippingURLs: previouslyDownloadedURLs.map { $0.absoluteString },
      withReply: { downloadedEpisodes, error in
        DispatchQueue.main.async {
          switch (downloadedEpisodes, error) {
          case (let rawDownloadedEpisodes?, nil):
            completion(.success(rawDownloadedEpisodes.map { DownloadedEpisode(dictionary: $0)! }))
          case (nil, let error?):
            completion(.failure(error))
          default:
            fatalError("Bad service reply")
          }
        }
      }
    )
  }
  
  func download(
    episode: Episode,
    downloadOptions: DownloadOptions,
    completion: @escaping (Result<DownloadedEpisode, Error>) -> Void) {
    service.download(
      episode: episode.dictionaryRepresentation,
      toBookmark: downloadOptions.containerDirectoryBookmark,
      organizingByShow: downloadOptions.shouldOrganizeByShow,
      savingMagnetLinks: downloadOptions.shouldSaveMagnetLinks,
      withReply: { downloadedFile, error in
        DispatchQueue.main.async {
          switch (downloadedFile, error) {
          case (let rawDownloadedFile?, nil):
            completion(.success(DownloadedEpisode(dictionary: rawDownloadedFile)!))
          case (nil, let error?):
            completion(.failure(error))
          default:
            fatalError("Bad service reply")
          }
        }
      }
    )
  }
}
