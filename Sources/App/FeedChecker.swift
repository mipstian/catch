import Foundation
import AppKit
import os


enum FeedCheckerError: Error {
  case serviceCrashed
}


private extension Timer {
  /// Invoke handler immediately, and reset the timer
  /// (i.e. the next scheduled time will be after a full `interval`).
  func fireNow() {
    fireDate = .distantPast
  }
}


private extension TimeInterval {
  /// How often to check feeds.
  static let feedUpdateInterval: TimeInterval = 60 * 10
  
  /// How much leeway to give to the os for scheduling.
  static let feedUpdateIntervalTolerance: TimeInterval = 30
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
  private var intervalTimer: Timer!
  
  private init() {
    intervalTimer = Timer.scheduledTimer(
      withTimeInterval: .feedUpdateInterval,
      repeats: true,
      block: { [weak self] _ in
        guard let self = self else { return }
        
        // Skip if paused or if current time is outside user-defined range
        guard self.status == .polling, !Defaults.shared.restricts(date: Date()) else { return }
        
        self.checkFeeds()
      }
    )
    intervalTimer.tolerance = .feedUpdateIntervalTolerance
    
    // Check now
    intervalTimer.fireNow()
    
    feedHelperProxy.delegate = self
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
      os_log("Skipping feed check: downloads directory is not available", log: .helper, type: .info)
      lastCheckStatus = .skipped(Date())
      return
    }
    
    // Only work with valid preferences
    guard
      Defaults.shared.isConfigurationValid,
      Defaults.shared.hasValidFeeds,
      let downloadOptions = Defaults.shared.downloadOptions
    else {
      os_log("Skipping feed check: invalid preferences", log: .helper, type: .info)
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
          os_log("Checking feed succeeded, %d new episodes found", log: .main, type: .info, downloadedEpisodes.count)
          // Deal with new files
          self?.handleDownloadedEpisodes(downloadedEpisodes)
          self?.lastCheckStatus = .successful(Date())
        case .failure(let error):
          os_log("Feed Helper error (checking feed): %{public}@", log: .main, type: .error, error.localizedDescription)
          self?.lastCheckStatus = .failed(Date(), error)
        }
        
        // Synchronize defaults here. If the app dies uncleanly, no data loss.
        Defaults.shared.save()
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
          addToDownloadHistory()
          if episode.url.isMagnetLink {
            // Open magnet link
            NSWorkspace.shared.openInBackground(url: episode.url)
          } else {
            // Open torrent file
            NSWorkspace.shared.openInBackground(file: downloadedEpisode.localURL!.path)
          }
        }
      } else {
        addToDownloadHistory()
      }
      
      NSUserNotificationCenter.default.deliverNewEpisodeNotification(for: episode)
    }
  }
  
  private func postStateChangedNotification() {
    NotificationCenter.default.post(name: FeedChecker.stateChangedNotification, object: self)
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
