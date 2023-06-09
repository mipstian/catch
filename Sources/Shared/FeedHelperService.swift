import Foundation


let feedHelperErrorDomain = "com.giorgiocalderolla.Catch.CatchFeedHelper"


@objc protocol FeedHelperService {
  func checkFeeds(
    urls: [String],
    downloadingToBookmark downloadDirectoryBookmark: Data,
    organizingByShow shouldOrganizeByShow: Bool,
    savingMagnetLinks shouldSaveMagnetLinks: Bool,
    skippingURLs previouslyDownloadedURLs: [String],
    withReply reply: @escaping (_ downloadedFeedFiles: [[AnyHashable:Any]]?, _ error: Error?) -> Void
  )
  
  func download(
    episode: [AnyHashable:Any],
    toBookmark downloadDirectoryBookmark: Data,
    organizingByShow shouldOrganizeByShow: Bool,
    savingMagnetLinks shouldSaveMagnetLinks: Bool,
    withReply reply: @escaping (_ downloadedFile: [AnyHashable:Any]?, _ error: Error?) -> Void
  )
}
