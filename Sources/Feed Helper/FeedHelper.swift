import Foundation


/// Implements the two functions of the Feed Helper service:
/// - Checking feeds (optionally downloading any new torrent files)
/// - Downloading a single torrent file
enum FeedHelper {
  static func checkFeeds(urls: [URL], downloadOptions: DownloadOptions, skippingURLs previouslyDownloadedURLs: [URL]) throws -> [DownloadedEpisode] {
    return try urls.flatMap {
      try checkFeed(url: $0, downloadOptions: downloadOptions, skippingURLs: previouslyDownloadedURLs)
    }
  }
  
  private static func checkFeed(url: URL, downloadOptions: DownloadOptions, skippingURLs previouslyDownloadedURLs: [URL]) throws -> [DownloadedEpisode] {
    NSLog("Checking feed: \(url)")
    
    // Flush the cache, we want fresh results
    URLCache.shared.removeAllCachedResponses()
    
    // Download the feed
    let feed: Data
    do {
      feed = try Data(contentsOf: url)
    } catch {
      throw NSError(
        domain: feedHelperErrorDomain,
        code: -5,
        userInfo: [
          NSLocalizedDescriptionKey: "Could not download feed",
          NSUnderlyingErrorKey: error
        ]
      )
    }
    
    // Parse the feed
    let episodes: [Episode]
    do {
      episodes = try FeedParser.parse(feed: feed)
    } catch {
      throw NSError(
        domain: feedHelperErrorDomain,
        code: -6,
        userInfo: [
          NSLocalizedDescriptionKey: "Could not parse feed",
          NSUnderlyingErrorKey: error
        ]
      )
    }
    
    // Skip old episodes
    let newEpisodes = episodes.filter { !previouslyDownloadedURLs.contains($0.url) }
    
    guard !newEpisodes.isEmpty else {
      NSLog("No new episodes to download")
      return []
    }
    
    // Download new episodes
    NSLog("Downloading \(newEpisodes.count) new episodes")
    let downloader = EpisodeDownloader(downloadOptions: downloadOptions)
    return try newEpisodes.map(downloader.download(episode:))
  }
  
  static func download(episode: Episode, downloadOptions: DownloadOptions) throws -> DownloadedEpisode {
    NSLog("Downloading single episode")

    let downloader = EpisodeDownloader(downloadOptions: downloadOptions)
    return try downloader.download(episode: episode)
  }
}
