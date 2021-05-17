import Foundation


/// Downloads episodes to the file system.
///
/// - Note: does not download the *contents* of torrent files, that is delegated
///         to any torrent client app.
struct EpisodeDownloader {
  let downloadOptions: DownloadOptions
  
  func download(episode: Episode) throws -> DownloadedEpisode {
    if episode.url.isMagnetLink {
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
      return DownloadedEpisode(episode: episode, localURL: nil)
    } else if downloadOptions.shouldSaveTorrentFiles {
      // Treat episode url as torrent file and download
      let downloadedTorrentFile: URL
      do {
        downloadedTorrentFile = try downloadTorrentFile(for: episode)
      } catch {
        NSLog("Could not download \(episode.url): \(error)")
        throw error
      }
      
      return DownloadedEpisode(episode: episode, localURL: downloadedTorrentFile)
    } else {
      // Treat episode url agnostically, just return it
      return DownloadedEpisode(episode: episode, localURL: nil)
    }
  }
  
  /// Create a .webloc file that can be double-clicked to open the magnet link
  private func saveMagnetLink(for episode: Episode) throws -> URL {
    precondition(episode.url.isMagnetLink)
    
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
    NSLog("Downloading torrent file \(episode.url)")
    
    // Download!
    let urlResponse: URLResponse
    let fileData: Data
    do {
      (urlResponse, fileData) = try URLSession.shared.downloadSynchronously(
        url: episode.url
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
    
    NSLog("Download complete, filesize: \(fileData.count)")
    
    // Try to get a nice filename from the episode's title
    let fileName = episode.title.torrentFileName
    
    // Build destination path
    let fullPath = URL(
      containerDirectory: downloadOptions.containerDirectory,
      subDirectory: downloadOptions.shouldOrganizeByShow ? episode.showName : nil,
      fileName: fileName
    )
    
    try fileData.writeWithIntermediateDirectories(to: fullPath)
    
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


private extension URLSession {
  func downloadSynchronously(url: URL) throws -> (URLResponse, Data) {
    let urlRequest = URLRequest(url: url)
    
    var downloadError: Error? = nil
    var downloadedData: Data!
    var urlResponse: URLResponse!
    
    let taskSemaphore = DispatchSemaphore(value: 0)
    URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
      if let error = error {
        downloadError = error
      } else {
        downloadedData = data!
        urlResponse = response!
      }
      taskSemaphore.signal()
    }.resume()
    taskSemaphore.wait()
    
    if let downloadError = downloadError {
      throw downloadError
    } else {
      return (urlResponse, downloadedData)
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
