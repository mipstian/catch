import Foundation


class FeedHelper: NSObject {
  static let shared = FeedHelper()
  
  private override init() {}
}


extension FeedHelper: FeedHelperService {
  func checkShowRSSFeed(
    feedURL: URL,
    downloadingToBookmark downloadFolderBookmark: Data,
    organizingByFolder shouldOrganizeByFolder: Bool,
    savingMagnetLinks shouldSaveMagnetLinks: Bool,
    skippingURLs previouslyDownloadedURLs: [String],
    withReply reply: (_ downloadedFeedFiles: [[AnyHashable:Any]], _ error: Error?) -> Void) {
    NSLog("Checking feed")
    
    // Resolve the bookmark (that the main app gives us to transfer access to
    // the download folder) to a URL
    let downloadFolderURL: URL
    do {
      downloadFolderURL = try FileUtils.url(from: downloadFolderBookmark)
    } catch {
      reply([], error)
      return
    }
    
    let downloadFolderPath = downloadFolderURL.path
    
    // Download the feed
    let feed: XMLDocument
    do {
      feed = try downloadFeed(feedURL: feedURL)
    } catch {
      reply([], NSError(
        domain: feedHelperErrorDomain,
        code: -5,
        userInfo: [
          NSLocalizedDescriptionKey: "Could not download feed",
          NSUnderlyingErrorKey: error
        ]
      ))
      return
    }
    
    // Parse the feed for files
    let feedFiles: [FeedParser.FeedItem]
    do {
      feedFiles = try FeedParser.parse(feed: feed)
    } catch {
      reply([], NSError(
        domain: feedHelperErrorDomain,
        code: -6,
        userInfo: [
          NSLocalizedDescriptionKey: "Could not parse feed",
          NSUnderlyingErrorKey: error
        ]
      ))
      return
    }
    
    // Download the files
    let downloadedFeedFiles: [[AnyHashable:Any]]
    do {
      downloadedFeedFiles = try downloadFiles(
        feedFiles: feedFiles,
        toPath: downloadFolderPath,
        organizingByFolder: shouldOrganizeByFolder,
        savingMagnetLinks: shouldSaveMagnetLinks,
        skippingURLs: previouslyDownloadedURLs
      )
    } catch {
      reply([], error)
      return
    }
    
    reply(downloadedFeedFiles, nil)
  }
  
  func downloadFile(
    file: [AnyHashable:Any],
    toBookmark downloadFolderBookmark: Data,
    organizingByFolder shouldOrganizeByFolder: Bool,
    savingMagnetLinks shouldSaveMagnetLinks: Bool,
    withReply reply: (_ downloadedFile: [AnyHashable:Any]?, _ error: Error?) -> Void) {
    NSLog("Downloading single file")
    
    // Resolve the bookmark (that the main app gives us to transfer access to
    // the download folder) to a URL
    let downloadFolderURL: URL
    do {
      downloadFolderURL = try FileUtils.url(from: downloadFolderBookmark)
    } catch {
      reply(nil, error)
      return
    }
    
    let downloadFolderPath = downloadFolderURL.path
    
    // Download the file
    let downloadedFiles: [[AnyHashable:Any]]
    do {
      downloadedFiles = try downloadFiles(
        feedFiles: [file],
        toPath: downloadFolderPath,
        organizingByFolder: shouldOrganizeByFolder,
        savingMagnetLinks: shouldSaveMagnetLinks,
        skippingURLs: []
      )
    } catch {
      reply(nil, error)
      return
    }
    
    reply(downloadedFiles.first, nil)
  }
}


// MARK: private utilities
fileprivate extension FeedHelper {
  func downloadFeed(feedURL: URL) throws -> XMLDocument {
    NSLog("Downloading feed \(feedURL)")
    
    // Flush the cache, we want fresh results
    URLCache.shared.removeAllCachedResponses()
    
    return try XMLDocument(contentsOf: feedURL, options: 0)
  }
  
  func downloadFiles(
    feedFiles: [[AnyHashable:Any]],
    toPath downloadPath: String,
    organizingByFolder shouldOrganizeByFolder: Bool,
    savingMagnetLinks shouldSaveMagnetLinks: Bool,
    skippingURLs previouslyDownloadedURLs: [String]) throws -> [[AnyHashable:Any]] {
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
      
      // First get the folder, if we want it and it's available
      let showName = shouldOrganizeByFolder ? fileShowName : nil
      
      // The file is new, return/save magnet or download torrent
      if isMagnetLink {
        let downloadedItemDescription: [AnyHashable:Any] = [
          "url": fileURL,
          "title": fileTitle,
          "isMagnetLink": true
        ]
        
        if shouldSaveMagnetLinks {
          // Save the magnet link to a file
          do {
            _ = try saveMagnetFile(
              file: file,
              toPath: downloadPath,
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
        let downloadedTorrentFile: String
        do {
          downloadedTorrentFile = try downloadFile(
            file: file,
            toPath: downloadPath,
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
          "torrentFilePath": downloadedTorrentFile
        ]
      }
    }
  }
  
  /// Create a .webloc file that can be double-clicked to open the magnet link
  func saveMagnetFile(
    file: [AnyHashable:Any],
    toPath downloadPath: String,
    withShowName showName: String?) throws -> String {
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
    let pathAndFilename = fullPathWithContainerFolder(
      containerFolder: downloadPath,
      suggestedSubFolder: showName,
      filename: filename
    )
    
    try writeData(data: data, toPath: pathAndFilename)
    
    return pathAndFilename
  }
  
  func downloadFile(
    file: [AnyHashable:Any],
    toPath downloadPath: String,
    withShowName showName: String?) throws -> String {
    // TODO: should be a struct
    let fileURL = URL(string: file["url"] as! String)!
    let fileTitle = file["title"] as! String
    
    if let showName = showName {
      NSLog("Downloading file to folder for show \(showName)")
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
    let pathAndFilename = fullPathWithContainerFolder(
      containerFolder: downloadPath,
      suggestedSubFolder: showName,
      filename: filename
    )
    
    try writeData(data: downloadedFile, toPath: pathAndFilename)
    
    return pathAndFilename
  }
  
  func writeData(data: Data, toPath pathAndFilename: String) throws {
    let url = URL(fileURLWithPath: pathAndFilename)
    let pathAndFolder = url.deletingLastPathComponent()
    
    // Check if the destination dir exists, if it doesn't create it
    var pathAndFolderIsDirectory: ObjCBool = false
    if FileManager.default.fileExists(atPath: pathAndFolder.path, isDirectory: &pathAndFolderIsDirectory) {
      if !pathAndFolderIsDirectory.boolValue {
        // Exists but isn't a directory! Aaargh! Abort!
        throw NSError(
          domain: feedHelperErrorDomain,
          code: -2,
          userInfo: [
            NSLocalizedDescriptionKey: "Download path is not a directory: \(pathAndFolder)"
          ]
        )
      }
    } else {
      // Create folder
      do {
        try FileManager.default.createDirectory(
          atPath: pathAndFolder.path,
          withIntermediateDirectories: true
        )
      } catch {
        // Folder creation failed :( Abort
        throw NSError(
          domain: feedHelperErrorDomain,
          code: -3,
          userInfo: [
            NSLocalizedDescriptionKey: "Couldn't create folder: \(pathAndFolder)",
            NSUnderlyingErrorKey: error
          ]
        )
      }
      
      NSLog("Folder \(pathAndFolder) created")
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
  
  func fullPathWithContainerFolder(
    containerFolder: String,
    suggestedSubFolder: String?,
    filename: String) -> String {
    var containerFolderURL = URL(fileURLWithPath: containerFolder)
    
    if let suggestedSubFolder = suggestedSubFolder {
      let folder = FileUtils.fileName(from: suggestedSubFolder)
      containerFolderURL.appendPathComponent(folder)
    }
    
    containerFolderURL.appendPathComponent(filename)
    
    return containerFolderURL.standardizedFileURL.path
  }
}


extension FeedHelper: NSXPCListenerDelegate {
  func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
    newConnection.exportedInterface = NSXPCInterface(with: FeedHelperService.self)
    newConnection.exportedObject = self
    newConnection.resume()
    
    return true
  }
}
