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
    case failed(Date, Error)
  }
  
  static let shared = FeedChecker()
  
  /// Posted whenever the status or last check status changes
  static let stateChangedNotification = NSNotification.Name("FeedChecker.stateChangedNotification")
  
  /// Current checker status.
  /// This can be changed by users with "Pause" and "Resume".
  var status: Status = .polling {
    didSet {
      // If we have just been set to polling, check immediately
      if oldValue == .paused && status == .polling {
        intervalTimer.fireNow()
      }
      
      postStateChangedNotification()
    }
  }
  
  /// What happened with the last feed check
  fileprivate(set) var lastCheckStatus: LastCheckStatus = .neverHappened {
    didSet {
      postStateChangedNotification()
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
  
  fileprivate func checkFeed() {
    // Don't check twice simultaneously
    guard lastCheckStatus != .inProgress else { return }
    
    // Only work with valid preferences
    guard
      Defaults.shared.isConfigurationValid,
      let downloadOptions = Defaults.shared.downloadOptions,
      let feedURL = Defaults.shared.feedURL
    else {
      NSLog("Refusing to check feed - invalid preferences")
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
    let shouldOpenTorrentsAutomatically = Defaults.shared.shouldOpenTorrentsAutomatically
    
    for downloadedEpisode in downloadedEpisodes.reversed() {
      let episode = downloadedEpisode.episode
      
      // Open magnet link, if requested
      if episode.isMagnetized && shouldOpenTorrentsAutomatically {
        Browser.openInBackground(url: episode.url)
      }
      
      // Open normal torrent in torrent client, if requested
      if !episode.isMagnetized && shouldOpenTorrentsAutomatically {
        Browser.openInBackground(file: downloadedEpisode.localURL!.path)
      }
      
      NSUserNotificationCenter.default.deliverNotification(newEpisode: episode)
      
      // Add to history
      let newHistoryItem = HistoryItem(episode: episode, downloadDate: Date())
      Defaults.shared.downloadHistory = [newHistoryItem] + Defaults.shared.downloadHistory
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
