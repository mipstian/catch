import Foundation
import os


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
    os_log("Checking feed: %{public}@", log: .helper, type: .info, "\(feed.url)")
    
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
      os_log("No new episodes to download", log: .helper, type: .info)
      return []
    }
    
    // Download new episodes
    os_log("Downloading %d new episodes", log: .helper, type: .info, newEpisodes.count)
    let downloader = EpisodeDownloader(downloadOptions: downloadOptions)
    let downloadedEpisodes = try newEpisodes.map(downloader.download(episode:))
    os_log("Done downloading new episodes", log: .helper, type: .info)
    return downloadedEpisodes
  }
  
  static func download(episode: Episode, downloadOptions: DownloadOptions) throws -> DownloadedEpisode {
    os_log("Downloading single episode", log: .helper, type: .info)

    let downloader = EpisodeDownloader(downloadOptions: downloadOptions)
    return try downloader.download(episode: episode)
  }
}
