import Foundation
import AppKit


enum FeedCheckerError: Error {
  case serviceCrashed
}


/// Singleton. Periodically invokes the Feed Helper service to check the feeds.
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
  
  /// Checks feeds right now ignoring time restrictions and "paused" mode
  func forceCheck() {
    checkFeeds()
  }
  
  private func checkFeeds() {
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
      Defaults.shared.hasValidFeeds,
      let downloadOptions = Defaults.shared.downloadOptions
    else {
      NSLog("Skipping feed check: invalid preferences")
      lastCheckStatus = .skipped(Date())
      return
    }
    
    lastCheckStatus = .inProgress
    
    // Extract URLs from history
    let previouslyDownloadedURLs = Defaults.shared.downloadHistory.map { $0.episode.url }
    
    // Check feeds
    feedHelperProxy.checkFeeds(
      feeds: Defaults.shared.feeds,
      downloadOptions: downloadOptions,
      previouslyDownloadedURLs: previouslyDownloadedURLs,
      completion: { [weak self] result in
        switch result {
        case .success(let downloadedEpisodes):
          // Deal with new files
          self?.handleDownloadedEpisodes(downloadedEpisodes)
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
      let historyItem = HistoryItem(episode: episode, downloadDate: Date())
      
      func addToDownloadHistory() {
        Defaults.shared.downloadHistory.append(historyItem)
      }
      
      // Open torrents automatically if requested
      if Defaults.shared.shouldOpenTorrentsAutomatically {
        if Defaults.shared.isDownloadScriptEnabled {
          Process.runDownloadScript(url: episode.url) { success in
            if success {
              addToDownloadHistory()
            }
          }
        } else {
          if episode.url.isMagnetLink {
            // Open magnet link
            NSWorkspace.shared.openInBackground(url: episode.url)
            addToDownloadHistory()
          } else {
            // Open torrent file
            NSWorkspace.shared.openInBackground(file: downloadedEpisode.localURL!.path)
            addToDownloadHistory()
          }
        }
      }
      
      NSUserNotificationCenter.default.deliverNewEpisodeNotification(for: episode)
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
    
    checkFeeds()
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
