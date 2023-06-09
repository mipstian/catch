import Foundation


let feedHelperErrorDomain = "com.giorgiocalderolla.Catch.CatchFeedHelper"


@objc protocol FeedHelperService {
  typealias FeedCheckReply = (_ downloadedFeedFiles: [[AnyHashable:Any]]?, _ error: Error?) -> Void
  typealias FileDownloadReply = (_ downloadedFile: [AnyHashable:Any]?, _ error: Error?) -> Void
  
  func checkFeed(
    url: URL,
    downloadingToBookmark downloadDirectoryBookmark: Data,
    organizingByShow shouldOrganizeByShow: Bool,
    savingMagnetLinks shouldSaveMagnetLinks: Bool,
    skippingURLs previouslyDownloadedURLs: [String],
    withReply reply: FeedCheckReply
  )
  
  func download(
    file: [AnyHashable:Any],
    toBookmark downloadDirectoryBookmark: Data,
    organizingByShow shouldOrganizeByShow: Bool,
    savingMagnetLinks shouldSaveMagnetLinks: Bool,
    withReply reply: FileDownloadReply
  )
}
