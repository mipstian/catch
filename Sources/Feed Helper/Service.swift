import Foundation


/// Implements the FeedHelperService XPC protocol, and handles serialization/deserialization
final class Service: NSObject {}


extension Service: FeedHelperService {
  func checkFeeds(
    feeds: [[AnyHashable:Any]],
    downloadingToBookmark downloadDirectoryBookmark: Data,
    organizingByShow shouldOrganizeByShow: Bool,
    savingMagnetLinks shouldSaveMagnetLinks: Bool,
    savingTorrentFiles shouldSaveTorrentFiles: Bool,
    skippingURLs previouslyDownloadedURLs: [String],
    withReply reply: @escaping (_ downloadedFeedFiles: [[AnyHashable:Any]]?, _ error: Error?) -> Void) {
    let downloadedEpisodes: [DownloadedEpisode]
    
    do {
      let downloadOptions = try DownloadOptions(
        containerDirectoryBookmark: downloadDirectoryBookmark,
        shouldOrganizeByShow: shouldOrganizeByShow,
        shouldSaveMagnetLinks: shouldSaveMagnetLinks,
        shouldSaveTorrentFiles: shouldSaveTorrentFiles
      )
      
      downloadedEpisodes = try FeedHelper.checkFeeds(
        feeds: feeds.map { Feed(dictionary: $0)! },
        downloadOptions: downloadOptions,
        skippingURLs: previouslyDownloadedURLs.map { URL.init(string: $0)! }
      )
    } catch {
      reply(nil, error)
      return
    }
    
    reply(downloadedEpisodes.map { $0.dictionaryRepresentation }, nil)
  }
  
  func download(feed: [AnyHashable : Any], withReply reply: @escaping (Data?, Error?) -> Void) {
    let feedContents: Data
    
    do {
      feedContents = try FeedHelper.downloadFeed(
        feed: Feed(dictionary: feed)!
      )
    } catch {
      reply(nil, error)
      return
    }
    
    reply(feedContents, nil)
  }
  
  func download(
    episode: [AnyHashable:Any],
    toBookmark downloadDirectoryBookmark: Data,
    organizingByShow shouldOrganizeByShow: Bool,
    savingMagnetLinks shouldSaveMagnetLinks: Bool,
    savingTorrentFiles shouldSaveTorrentFiles: Bool,
    withReply reply: @escaping (_ downloadedFile: [AnyHashable:Any]?, _ error: Error?) -> Void) {
    let downloadedFile: DownloadedEpisode
    
    do {
      let downloadOptions = try DownloadOptions(
        containerDirectoryBookmark: downloadDirectoryBookmark,
        shouldOrganizeByShow: shouldOrganizeByShow,
        shouldSaveMagnetLinks: shouldSaveMagnetLinks,
        shouldSaveTorrentFiles: shouldSaveTorrentFiles
      )
      
      downloadedFile = try FeedHelper.download(
        episode: Episode(dictionary: episode)!,
        downloadOptions: downloadOptions
      )
    } catch {
      reply(nil, error)
      return
    }
    
    reply(downloadedFile.dictionaryRepresentation, nil)
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
