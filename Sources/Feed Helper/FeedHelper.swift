import Foundation


/// Implements the two functions of the Feed Helper service:
/// - Checking feeds (optionally downloading any new torrent files)
/// - Downloading a single torrent file
enum FeedHelper {
  static func checkFeeds(feeds: [Feed], downloadOptions: DownloadOptions, skippingURLs previouslyDownloadedURLs: [URL]) throws -> [DownloadedEpisode] {
    return try feeds.flatMap {
      try checkFeed(feed: $0, downloadOptions: downloadOptions, skippingURLs: previouslyDownloadedURLs)
    }
  }
  
  static func downloadFeed(feed: Feed) throws -> Data {
    // Flush the cache, we want fresh results
    URLCache.shared.removeAllCachedResponses()
    
    let feedContents: Data
    do {
      feedContents = try Data(contentsOf: feed.url)
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
    
    return feedContents
  }
  
  private static func checkFeed(feed: Feed, downloadOptions: DownloadOptions, skippingURLs previouslyDownloadedURLs: [URL]) throws -> [DownloadedEpisode] {
    NSLog("Checking feed: \(feed.url)")
    
    // Download the feed
    let feedContents = try downloadFeed(feed: feed)
    
    // Parse the feed
    let episodes: [Episode]
    do {
      episodes = try FeedParser.parse(feed: feed, feedContents: feedContents)
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
