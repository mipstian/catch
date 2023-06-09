import Foundation


/// Periodically invokes the Feed Helper service to check a feed.
final class FeedChecker {
  static let statusChangedNotification = NSNotification.Name("FeedChecker.statusChangedNotification")
  static let shared = FeedChecker()
  
  /// True iff periodically checking the feed. This is the opposite
  /// of the user-facing "Paused" state.
  var isPolling = true {
    didSet {
      // If we have just been set to polling, check immediately
      if !oldValue && isPolling {
        scheduler.fireNow()
      }
      
      refreshPowerManagement()
      postStatusChangedNotification()
    }
  }
  
  /// True iff a feed check is happening right now
  private(set) var isChecking = false {
    didSet {
      postStatusChangedNotification()
    }
  }
  
  /// True iff the last feed check succeeded, or if no check has been made yet.
  private(set) var lastUpdateWasSuccessful = true
  
  /// The date/time of the last feed check, nil if no check has been made yet.
  private(set) var lastUpdateDate: Date? = nil
  
  private var activityToken: NSObjectProtocol? = nil
  
  private let feedHelperProxy = FeedHelperProxy()
  private let scheduler = Scheduler(interval: Config.feedUpdateInterval)
  
  private init() {
    feedHelperProxy.delegate = self
    
    scheduler.delegate = self

    // Check now
    scheduler.fireNow()

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
    guard isPolling else { return }
    
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
    guard !isChecking else { return }
    
    // Only work with valid preferences
    guard Defaults.shared.isConfigurationValid, let downloadOptions = Defaults.shared.downloadOptions else {
      NSLog("Refusing to check feed - invalid preferences")
      return
    }
    
    isChecking = true
    
    // Extract URLs from history
    let previouslyDownloadedURLs = Defaults.shared.downloadHistory.map { $0.url }
    
    // Check the feed
    feedHelperProxy.checkFeed(
      URL(string: Defaults.shared.feedURL)!,
      downloadOptions: downloadOptions,
      previouslyDownloadedURLs: previouslyDownloadedURLs,
      completion: { [weak self] downloadedFiles, error in
        if let error = error {
          NSLog("Feed Helper error (checking feed): \(error)")
        }
        
        // Deal with new files
        if let downloadedFiles = downloadedFiles {
          self?.handleDownloadedFeedFiles(downloadedFiles)
        }
        self?.handleFeedCheckCompletion(wasSuccessful: error == nil)
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

  fileprivate func handleFeedCheckCompletion(wasSuccessful: Bool) {
    isChecking = false
    lastUpdateWasSuccessful = wasSuccessful
    lastUpdateDate = Date()
    
    postStatusChangedNotification()
  }
  
  private func postStatusChangedNotification() {
    NotificationCenter.default.post(
      name: FeedChecker.statusChangedNotification,
      object: self
    )
  }
}


extension FeedChecker: SchedulerDelegate {
  func schedulerFired() {
    // Skip if paused
    guard isPolling else { return }
    
    // Skip if current time is outside user-defined range
    guard !Defaults.shared.restricts(date: Date()) else { return }
    
    checkFeed()
  }
}


extension FeedChecker: FeedHelperProxyDelegate {
  func feedHelperConnectionWasInterrupted() {
    if isChecking {
      handleFeedCheckCompletion(wasSuccessful: false)
      NSLog("Feed helper service crashed")
    } else {
      NSLog("Feed helper service went offline")
    }
  }
}
