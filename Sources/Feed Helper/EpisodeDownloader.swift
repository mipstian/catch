import Foundation


/// Downloads episodes to the file system.
///
/// - Note: does not download the *contents* of torrent files, that is delegated
///         to any torrent client app.
struct EpisodeDownloader {
  let downloadOptions: DownloadOptions
  
  func download(episode: Episode) throws -> [AnyHashable:Any] {
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
          _ = try saveMagnetLink(for: episode)
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
        downloadedTorrentFile = try downloadTorrentFile(for: episode)
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
  
  /// Create a .webloc file that can be double-clicked to open the magnet link
  private func saveMagnetLink(for episode: Episode) throws -> URL {
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
    
    // Try to get a nice filename from the episode's title
    let fileName = episode.title.weblocFileName
    
    // Build destination path
    let fullPath = URL(
      containerDirectory: downloadOptions.containerDirectory,
      subDirectory: downloadOptions.shouldOrganizeByShow ? episode.showName : nil,
      fileName: fileName
    )
    
    try data.writeWithIntermediateDirectories(to: fullPath)
    
    return fullPath
  }
  
  private func downloadTorrentFile(for episode: Episode) throws -> URL {
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
    
    // Try to get a nice filename from the episode's title
    let fileName = episode.title.torrentFileName
    
    // Build destination path
    let fullPath = URL(
      containerDirectory: downloadOptions.containerDirectory,
      subDirectory: downloadOptions.shouldOrganizeByShow ? episode.showName : nil,
      fileName: fileName
    )
    
    try downloadedFile.writeWithIntermediateDirectories(to: fullPath)
    
    return fullPath
  }
}


private extension Data {
  /// Write the contents of the Data to a location, creating intermediate directories if
  /// necessary.
  func writeWithIntermediateDirectories(to url: URL) throws {
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
      try write(to: url, options: .atomic)
    } catch {
      throw NSError(
        domain: feedHelperErrorDomain,
        code: -4,
        userInfo: [
          NSLocalizedDescriptionKey: "Couldn't write data to: \(url)",
          NSUnderlyingErrorKey: error
        ]
      )
    }
  }
}


private extension URL {
  init(containerDirectory: URL, subDirectory: String?, fileName: String) {
    var fullPath = containerDirectory
    
    if let subDirectory = subDirectory {
      fullPath.appendPathComponent(subDirectory.sanitizedForFileSystem)
    }
    
    fullPath.appendPathComponent(fileName)
    
    self = fullPath.standardizedFileURL
  }
}
