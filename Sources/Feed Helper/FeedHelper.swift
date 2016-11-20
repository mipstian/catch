import Foundation


enum FeedHelper {
  static func checkFeed(url: URL, downloadOptions: DownloadOptions, skippingURLs previouslyDownloadedURLs: [String]) throws -> [[AnyHashable:Any]] {
    NSLog("Checking feed: \(url)")
    
    // Download the feed
    let feed: Data
    do {
      feed = try downloadFeed(url: url)
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
    
    // Parse the feed for files
    let feedFiles: [FeedParser.FeedItem]
    do {
      feedFiles = try FeedParser.parse(feed: feed)
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
    
    // Download the files
    return try downloadFiles(
      feedFiles: feedFiles,
      downloadOptions: downloadOptions,
      skippingURLs: previouslyDownloadedURLs
    )
  }
  
  static func download(file: [AnyHashable:Any], downloadOptions: DownloadOptions) throws -> [AnyHashable:Any]? {
    NSLog("Downloading single file")

    // Download the file
    let downloadedFiles = try downloadFiles(
      feedFiles: [file],
      downloadOptions: downloadOptions
    )
    
    return downloadedFiles.first
  }
}


// MARK: private utilities
fileprivate extension FeedHelper {
  static func downloadFeed(url: URL) throws -> Data {
    NSLog("Downloading feed \(url)")
    
    // Flush the cache, we want fresh results
    URLCache.shared.removeAllCachedResponses()
    
    return try Data(contentsOf: url)
  }
  
  static func downloadFiles(
    feedFiles: [[AnyHashable:Any]],
    downloadOptions: DownloadOptions,
    skippingURLs previouslyDownloadedURLs: [String] = []) throws -> [[AnyHashable:Any]] {
    NSLog("Downloading files (if needed)")
    
    return try feedFiles.flatMap { file in
      // TODO: should be a struct
      let fileURL = file["url"] as! String
      let fileTitle = file["title"] as! String
      let fileShowName = file["showName"] as? String
      
      // Skip old files, invalid URLs
      guard !previouslyDownloadedURLs.contains(fileURL),
        let url = URL(string: fileURL) else {
        return nil
      }
      
      let isMagnetLink = url.scheme == "magnet"
      
      // First get the name for the show's directory, if we want it and it's available
      let showName = downloadOptions.shouldOrganizeByShow ? fileShowName : nil
      
      // The file is new, return/save magnet or download torrent
      if isMagnetLink {
        let downloadedItemDescription: [AnyHashable:Any] = [
          "url": fileURL,
          "title": fileTitle,
          "isMagnetLink": true
        ]
        
        if downloadOptions.shouldSaveMagnetLinks {
          // Save the magnet link to a file
          do {
            _ = try saveMagnetFile(
              file: file,
              to: downloadOptions.containerDirectory,
              withShowName: showName
            )
          } catch {
            NSLog("Could not save magnet link \(fileURL): \(error)")
            throw error
          }
        }
        
        // Return the magnet link, if needed the main app will open it on the fly
        return downloadedItemDescription
      } else {
        let downloadedTorrentFile: URL
        do {
          downloadedTorrentFile = try downloadFile(
            file: file,
            to: downloadOptions.containerDirectory,
            withShowName: showName
          )
        } catch {
          NSLog("Could not download \(fileURL): \(error)")
          throw error
        }
        
        return [
          "url": fileURL,
          "title": fileTitle,
          "isMagnetLink": false,
          "torrentFilePath": downloadedTorrentFile.absoluteString
        ]
      }
    }
  }
  
  /// Create a .webloc file that can be double-clicked to open the magnet link
  static func saveMagnetFile(
    file: [AnyHashable:Any],
    to containerDirectory: URL,
    withShowName showName: String?) throws -> URL {
    // TODO: should be a struct
    let fileURL = URL(string: file["url"] as! String)!
    let fileTitle = file["title"] as! String
    
    let data: Data
    do {
      data = try PropertyListSerialization.weblocData(from: fileURL)
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
    let filename = FileUtils.magnetFilename(from: fileTitle)
    
    // Compute destination path
    let fullPath = downloadPath(
      in: containerDirectory,
      subDirectory: showName,
      filename: filename
    )
    
    try writeData(data: data, to: fullPath)
    
    return fullPath
  }
  
  static func downloadFile(
    file: [AnyHashable:Any],
    to containerDirectory: URL,
    withShowName showName: String?) throws -> URL {
    // TODO: should be a struct
    let fileURL = URL(string: file["url"] as! String)!
    let fileTitle = file["title"] as! String
    
    if let showName = showName {
      NSLog("Downloading file to directory for show \(showName)")
    } else {
      NSLog("Downloading file")
    }
    
    // Download!
    let urlRequest = URLRequest(url: fileURL)
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
          NSLocalizedDescriptionKey: "Could not download file",
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
          NSLocalizedDescriptionKey: "Could not download file (bad status code \(httpResponse.statusCode))"
        ]
      )
    }
    
    NSLog("Download complete, filesize: \(downloadedFile.count)")
    
    // Try to get a nice filename
    let filename = FileUtils.torrentFilename(from: fileTitle)
    
    // Compute destination path
    let fullPath = downloadPath(
      in: containerDirectory,
      subDirectory: showName,
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
