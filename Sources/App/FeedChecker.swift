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
      
      refreshPowerManagement()
      postStateChangedNotification()
    }
  }
  
  /// What happened with the last feed check
  fileprivate(set) var lastCheckStatus: LastCheckStatus = .neverHappened {
    didSet {
      postStateChangedNotification()
    }
  }
  
  private var activityToken: NSObjectProtocol? = nil
  
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

    refreshPowerManagement()
  }
  
  /// Checks feed right now ignoring time restrictions and "paused" mode
  func forceCheck() {
    checkFeed()
  }
  
  /// Makes the app's power management status (App Nap and system sleep) reflect the
  /// current app state and settings
  func refreshPowerManagement() {
    // End previously started activity if any
    if let token = activityToken {
      ProcessInfo.processInfo.endActivity(token)
      activityToken = nil
    }
    
    // No need to prevent App Nap or system sleep if paused
    guard status == .polling else { return }
    
    // Prevent App Nap (so we can keep checking the feed), and optionally system sleep
    activityToken = ProcessInfo.processInfo.beginActivity(
      options: Defaults.shared.shouldPreventSystemSleep ?
        [.suddenTerminationDisabled, .idleSystemSleepDisabled] :
        .suddenTerminationDisabled,
      reason: "Actively polling the feed"
    )
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
    let previouslyDownloadedURLs = Defaults.shared.downloadHistory.map { $0.url }
    
    // Check the feed
    feedHelperProxy.checkFeed(
      url: feedURL,
      downloadOptions: downloadOptions,
      previouslyDownloadedURLs: previouslyDownloadedURLs,
      completion: { [weak self] result in
        switch result {
        case .success(let downloadedFiles):
          // Deal with new files
          self?.handleDownloadedFeedFiles(downloadedFiles)
          self?.lastCheckStatus = .successful(Date())
        case .failure(let error):
          NSLog("Feed Helper error (checking feed): \(error)")
          self?.lastCheckStatus = .failed(Date(), error)
        }
      }
    )
  }
  
  private func handleDownloadedFeedFiles(_ downloadedFeedFiles: [[AnyHashable : Any]]) {
    let shouldOpenTorrentsAutomatically = Defaults.shared.shouldOpenTorrentsAutomatically
    
    for feedFile in downloadedFeedFiles.reversed() {
      let isMagnetLink = (feedFile["isMagnetLink"] as? NSNumber)?.boolValue ?? false
      
      // Open magnet link, if requested
      if isMagnetLink && shouldOpenTorrentsAutomatically {
        Browser.openInBackground(url: URL(string: feedFile["url"] as! String)!)
      }
      
      let torrentFilePath = feedFile["torrentFilePath"] as? String
      
      // Open normal torrent in torrent client, if requested
      if !isMagnetLink && shouldOpenTorrentsAutomatically {
        Browser.openInBackground(file: torrentFilePath!)
      }
      
      let title = feedFile["title"] as! String
      
      NSUserNotificationCenter.default.deliverNewEpisodeNotification(episodeTitle: title)
      
      let url = feedFile["url"] as! String
      
      // Add to history
      let newHistoryItem = HistoryItem(
        title: title,
        url: URL(string: url)!,
        downloadDate: Date(),
        isMagnetLink: isMagnetLink
      )
      Defaults.shared.downloadHistory = [newHistoryItem] + Defaults.shared.downloadHistory
    }
  }
  
  private func postStateChangedNotification() {
    NotificationCenter.default.post(
      name: FeedChecker.stateChangedNotification,
      object: self
    )
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
