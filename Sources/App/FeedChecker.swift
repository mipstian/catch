import Foundation


enum FeedCheckerError: Error {
  case serviceCrashed
}


/// Singleton. Periodically invokes the Feed Helper service to check a feed.
final class FeedChecker {
  enum Status {
    case polling, paused
  }
  
  enum LastCheckStatus {
    case neverHappened
    case inProgress
    case successful(Date)
    case skipped(Date)
    case failed(Date, Error)
  }
  
  static let shared = FeedChecker()
  
  /// Posted whenever the status or last check status changes
  static let stateChangedNotification = NSNotification.Name("FeedChecker.stateChangedNotification")
  
  /// Current checker status.
  /// This can be changed by users with "Pause" and "Resume".
  var status: Status = .polling {
    didSet {
      if oldValue != status {
        // If we have just been set to polling, check immediately
        if oldValue == .paused && status == .polling {
          intervalTimer.fireNow()
        }
        
        postStateChangedNotification()
      }
    }
  }
  
  /// What happened with the last feed check
  private(set) var lastCheckStatus: LastCheckStatus = .neverHappened {
    didSet {
      if oldValue != lastCheckStatus {
        postStateChangedNotification()
      }
    }
  }
  
  private let feedHelperProxy = FeedHelperProxy()
  private let intervalTimer = IntervalTimer(
    interval: Config.feedUpdateInterval,
    tolerance: Config.feedUpdateIntervalTolerance
  )
  
  private init() {
    feedHelperProxy.delegate = self
    
    intervalTimer.delegate = self

    // Check now
    intervalTimer.fireNow()
  }
  
  /// Checks feed right now ignoring time restrictions and "paused" mode
  func forceCheck() {
    checkFeed()
  }
  
  private func checkFeed() {
    // Don't check twice simultaneously
    guard lastCheckStatus != .inProgress else { return }
    
    // Skip check if downloads directory isn't currently available
    guard Defaults.shared.isTorrentsSavePathValid else {
      NSLog("Skipping feed check: downloads directory is not available")
      lastCheckStatus = .skipped(Date())
      return
    }
    
    // Only work with valid preferences
    guard
      Defaults.shared.isConfigurationValid,
      let downloadOptions = Defaults.shared.downloadOptions,
      let feedURL = Defaults.shared.feedURL
    else {
      NSLog("Skipping feed check: invalid preferences")
      lastCheckStatus = .skipped(Date())
      return
    }
    
    lastCheckStatus = .inProgress
    
    // Extract URLs from history
    let previouslyDownloadedURLs = Defaults.shared.downloadHistory.map { $0.episode.url }
    
    // Check the feed
    feedHelperProxy.checkFeed(
      url: feedURL,
      downloadOptions: downloadOptions,
      previouslyDownloadedURLs: previouslyDownloadedURLs,
      completion: { [weak self] result in
        switch result {
        case .success(let downloadedFiles):
          // Deal with new files
          self?.handleDownloadedEpisodes(downloadedFiles)
          self?.lastCheckStatus = .successful(Date())
        case .failure(let error):
          NSLog("Feed Helper error (checking feed): \(error)")
          self?.lastCheckStatus = .failed(Date(), error)
        }
      }
    )
  }
  
  private func handleDownloadedEpisodes(_ downloadedEpisodes: [DownloadedEpisode]) {
    for downloadedEpisode in downloadedEpisodes {
      let episode = downloadedEpisode.episode
      
      // Open torrents automatically if requested
      if Defaults.shared.shouldOpenTorrentsAutomatically {
        if episode.isMagnetized {
          // Open magnet link
          Browser.openInBackground(url: episode.url)
        } else {
          // Open torrent file
          Browser.openInBackground(file: downloadedEpisode.localURL!.path)
        }
      }
        
      // Run a script on the torrent if requested
      if Defaults.shared.runScript {
        let task = Process()
        let pipe = Pipe()
        task.launchPath = Defaults.shared.scriptPath?.path
        task.standardOutput = pipe
        
        if episode.isMagnetized {
          // Run the script using the magnet URL as the argument.
          task.arguments = [episode.url.absoluteString]
        } else {
          // Run the script using the file URL as the argument.
          task.arguments = [downloadedEpisode.localURL!.path]
        }
        
        task.launch()

        let handle = pipe.fileHandleForReading
        let data = handle.readDataToEndOfFile()
        let printing = String (data: data, encoding: String.Encoding.utf8)
        NSLog("%@", printing!)
      }
      
      NSUserNotificationCenter.default.deliverNewEpisodeNotification(for: episode)
      
      // Add to history
      Defaults.shared.downloadHistory.append(HistoryItem(episode: episode, downloadDate: Date()))
    }
  }
  
  private func postStateChangedNotification() {
    NotificationCenter.default.post(name: FeedChecker.stateChangedNotification, object: self)
  }
}


extension FeedChecker: IntervalTimerDelegate {
  func timerFired() {
    // Skip if paused or if current time is outside user-defined range
    guard status == .polling, !Defaults.shared.restricts(date: Date()) else { return }
    
    checkFeed()
  }
}


extension FeedChecker: FeedHelperProxyDelegate {
  func feedHelperConnectionWasInterrupted() {
    if lastCheckStatus == .inProgress {
      lastCheckStatus = .failed(Date(), FeedCheckerError.serviceCrashed)
    }
  }
}


extension FeedChecker.LastCheckStatus: Equatable {
  static func ==(lhs: FeedChecker.LastCheckStatus, rhs: FeedChecker.LastCheckStatus) -> Bool {
    switch (lhs, rhs) {
    case (.neverHappened, .neverHappened), (.inProgress, .inProgress): return true
    case (.successful(let lhsDate), .successful(let rhsDate)): return lhsDate == rhsDate
    case (.failed(let lhsDate, _), .failed(let rhsDate, _)): return lhsDate == rhsDate
    default: return false
    }
  }
}
