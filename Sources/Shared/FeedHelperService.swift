import Foundation


let feedHelperErrorDomain = "com.giorgiocalderolla.Catch.CatchFeedHelper"


@objc protocol FeedHelperService {
  func checkFeeds(
    feeds: [[AnyHashable:Any]],
    downloadingToBookmark downloadDirectoryBookmark: Data,
    organizingByShow shouldOrganizeByShow: Bool,
    savingMagnetLinks shouldSaveMagnetLinks: Bool,
    savingTorrentFiles shouldSaveTorrentFiles: Bool,
    skippingURLs previouslyDownloadedURLs: [String],
    withReply reply: @escaping (_ downloadedFeedFiles: [[AnyHashable:Any]]?, _ error: Error?) -> Void
  )
  
  func download(
    feed: [AnyHashable:Any],
    withReply reply: @escaping (_ downloadedFeed: Data?, _ error: Error?) -> Void
  )
  
  func download(
    episode: [AnyHashable:Any],
    toBookmark downloadDirectoryBookmark: Data,
    organizingByShow shouldOrganizeByShow: Bool,
    savingMagnetLinks shouldSaveMagnetLinks: Bool,
    savingTorrentFiles shouldSaveTorrentFiles: Bool,
    withReply reply: @escaping (_ downloadedFile: [AnyHashable:Any]?, _ error: Error?) -> Void
  )
}
