import Foundation


/// Implements the two functions of the Feed Helper service:
/// - Checking a feed (optionally downloading any new torrent files)
/// - Downloading a single torrent file
enum FeedHelper {
  static func checkFeed(url: URL, downloadOptions: DownloadOptions, skippingURLs previouslyDownloadedURLs: [URL]) throws -> [[AnyHashable:Any]] {
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
    
    // Download
    return try download(
      episodes: episodes,
      downloadOptions: downloadOptions,
      skippingURLs: previouslyDownloadedURLs
    )
  }
  
  static func download(episode: Episode, downloadOptions: DownloadOptions) throws -> [AnyHashable:Any]? {
    NSLog("Downloading single episode")

    let downloadedEpisodes = try download(
      episodes: [episode],
      downloadOptions: downloadOptions
    )
    
    return downloadedEpisodes.first
  }
}


// MARK: private utilities
fileprivate extension FeedHelper {
  static func download(
    episodes: [Episode],
    downloadOptions: DownloadOptions,
    skippingURLs previouslyDownloadedURLs: [URL] = []) throws -> [[AnyHashable:Any]] {
    // Skip old episodes
    let newEpisodes = episodes.filter {
      return !previouslyDownloadedURLs.contains($0.url)
    }
    
    guard !newEpisodes.isEmpty else {
      NSLog("No new episodes to download")
      return []
    }
    
    NSLog("Downloading \(newEpisodes.count) new episodes")
    
    return try newEpisodes.flatMap { episode in
      // Return/save magnet or download torrent
      if episode.isMagnetized {
        let downloadedItemDescription: [AnyHashable:Any] = [
          "url": episode.url,
          "title": episode.title,
          "isMagnetLink": true
        ]
        
        if downloadOptions.shouldSaveMagnetLinks {
          // Save the magnet link to a file
          do {
            _ = try saveMagnetLink(for: episode, downloadOptions: downloadOptions)
          } catch {
            NSLog("Could not save magnet link \(episode.url): \(error)")
            throw error
          }
        }
        
        // Return the magnet link, if needed the main app will open it on the fly
        return downloadedItemDescription
      } else {
        let downloadedTorrentFile: URL
        do {
          downloadedTorrentFile = try downloadTorrentFile(
            for: episode,
            downloadOptions: downloadOptions
          )
        } catch {
          NSLog("Could not download \(episode.url): \(error)")
          throw error
        }
        
        return [
          "url": episode.url,
          "title": episode.title,
          "isMagnetLink": false,
          "torrentFilePath": downloadedTorrentFile.absoluteString
        ]
      }
    }
  }
  
  /// Create a .webloc file that can be double-clicked to open the magnet link
  static func saveMagnetLink(for episode: Episode, downloadOptions: DownloadOptions) throws -> URL {
    precondition(episode.isMagnetized)
    
    let data: Data
    do {
      data = try PropertyListSerialization.weblocData(from: episode.url)
    } catch {
      throw NSError(
        domain: feedHelperErrorDomain,
        code: -8,
        userInfo: [
          NSLocalizedDescriptionKey: "Could not serialize magnet link plist"
        ]
      )
    }
    
    // Try to get a nice filename
    let filename = FileUtils.magnetFilename(from: episode.title)
    
    // Compute destination path
    let fullPath = downloadPath(
      in: downloadOptions.containerDirectory,
      subDirectory: downloadOptions.shouldOrganizeByShow ? episode.showName : nil,
      filename: filename
    )
    
    try writeData(data: data, to: fullPath)
    
    return fullPath
  }
  
  static func downloadTorrentFile(for episode: Episode, downloadOptions: DownloadOptions) throws -> URL {
    precondition(!episode.isMagnetized)
    
    NSLog("Downloading torrent file")
    
    // Download!
    let urlRequest = URLRequest(url: episode.url)
    var urlResponse: URLResponse?
    let downloadedFile: Data
    do {
      downloadedFile = try NSURLConnection.sendSynchronousRequest(
        urlRequest,
        returning: &urlResponse
      )
    } catch {
      throw NSError(
        domain: feedHelperErrorDomain,
        code: -1,
        userInfo: [
          NSLocalizedDescriptionKey: "Could not download torrent file",
          NSUnderlyingErrorKey: error
        ]
      )
    }
    
    let httpResponse = urlResponse as! HTTPURLResponse
    
    guard httpResponse.statusCode == 200 else {
      throw NSError(
        domain: feedHelperErrorDomain,
        code: -7,
        userInfo: [
          NSLocalizedDescriptionKey: "Could not download torrent file (bad status code \(httpResponse.statusCode))"
        ]
      )
    }
    
    NSLog("Download complete, filesize: \(downloadedFile.count)")
    
    // Try to get a nice filename
    let filename = FileUtils.torrentFilename(from: episode.title)
    
    // Compute destination path
    let fullPath = downloadPath(
      in: downloadOptions.containerDirectory,
      subDirectory: downloadOptions.shouldOrganizeByShow ? episode.showName : nil,
      filename: filename
    )
    
    try writeData(data: downloadedFile, to: fullPath)
    
    return fullPath
  }
  
  static func writeData(data: Data, to url: URL) throws {
    let containerDirectory = url.deletingLastPathComponent()
    
    // Check if the destination dir exists, if it doesn't create it
    var isDirectory: ObjCBool = false
    if FileManager.default.fileExists(atPath: containerDirectory.path, isDirectory: &isDirectory) {
      if !isDirectory.boolValue {
        // Exists but isn't a directory! Aaargh! Abort!
        throw NSError(
          domain: feedHelperErrorDomain,
          code: -2,
          userInfo: [
            NSLocalizedDescriptionKey: "Download path is not a directory: \(containerDirectory)"
          ]
        )
      }
    } else {
      // Directory doesn't exist, create it
      do {
        try FileManager.default.createDirectory(
          atPath: containerDirectory.path,
          withIntermediateDirectories: true
        )
      } catch {
        // Directory creation failed :( Abort
        throw NSError(
          domain: feedHelperErrorDomain,
          code: -3,
          userInfo: [
            NSLocalizedDescriptionKey: "Couldn't create directory: \(containerDirectory)",
            NSUnderlyingErrorKey: error
          ]
        )
      }
      
      NSLog("Directory \(containerDirectory) created")
    }
    
    // Write!
    do {
      try data.write(to: url, options: .atomicWrite)
    } catch {
      throw NSError(
        domain: feedHelperErrorDomain,
        code: -4,
        userInfo: [
          NSLocalizedDescriptionKey: "Couldn't save file to disk: \(url)",
          NSUnderlyingErrorKey: error
        ]
      )
    }
  }
  
  static func downloadPath(in containerDirectory: URL, subDirectory: String?, filename: String) -> URL {
    var fullPath = containerDirectory
    
    if let subDirectory = subDirectory {
      fullPath.appendPathComponent(FileUtils.fileName(from: subDirectory))
    }
    
    fullPath.appendPathComponent(filename)
    
    return fullPath.standardizedFileURL
  }
}
