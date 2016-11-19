import Foundation


final class Scheduler {
  static let statusChangedNotification = NSNotification.Name("scheduler-status-changed")
  static let shared = Scheduler()
  
  private(set) var isPolling = true { didSet { refreshActivity(); sendStatusChangedNotification() } }
  private(set) var isChecking = false { didSet { sendStatusChangedNotification() } }
  
  /// True iff the last feed check succeeded, or if no check has been made yet.
  private(set) var lastUpdateWasSuccessful = true
  
  /// The date/time of the last feed check, nil if no check has been made yet.
  private(set) var lastUpdateDate: Date? = nil
  
  private var shouldCheckNow: Bool {
    if !Defaults.shared.areTimeRestrictionsEnabled { return true }
    
    return Date().isTimeOfDayBetween(
      startTimeOfDay: Defaults.shared.fromDateForTimeRestrictions,
      endTimeOfDay: Defaults.shared.toDateForTimeRestrictions
    )
  }
  
  private var repeatingTimer: Timer! = nil
  private var activityToken: NSObjectProtocol? = nil
  
  private let feedHelperProxy = FeedHelperProxy()
  
  private init() {
    feedHelperProxy.delegate = self
    
    // Create a timer to check periodically
    repeatingTimer = Timer.scheduledTimer(
      timeInterval: Config.feedUpdateInterval,
      target: self,
      selector: #selector(tick),
      userInfo: nil,
      repeats: true
    )

    // Check now as well
    fireTimerNow()

    refreshActivity()
  }
  
  func togglePause() {
    isPolling = !isPolling
    
    // If we have just been set to polling, poll immediately
    if isPolling { fireTimerNow() }
  }
  
  func forceCheck() {
    // Check feed right now ignoring time restrictions and "paused" mode
    checkFeed()
  }
  
  func refreshActivity() {
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
  
  func downloadHistoryItem(_ historyItem: HistoryItem, completion: @escaping (([String:Any]?, Error?) -> ())) {
    guard Defaults.shared.isConfigurationValid, let downloadOptions = Defaults.shared.downloadOptions else {
      NSLog("Cannot download history item with invalid preferences")
      return
    }
    
    feedHelperProxy.downloadHistoryItem(
      historyItem,
      downloadOptions: downloadOptions,
      completion: { downloadedFile, error in
        if let error = error {
          NSLog("Feed Helper error (downloading file): \(error)")
        }
        
        completion(downloadedFile as? [String:Any], error)
      }
    )
  }
  
  private func checkFeed() {
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
    
    sendStatusChangedNotification()
  }

  @objc private func tick(_ timer: Timer) {
    // Don't check if paused or if current time is outside user-defined range
    guard isPolling && shouldCheckNow else { return }
    
    checkFeed()
  }
  
  private func fireTimerNow() {
    repeatingTimer.fireDate = .distantPast
  }
  
  private func sendStatusChangedNotification() {
    NotificationCenter.default.post(name: Scheduler.statusChangedNotification, object: self)
  }
}


extension Scheduler: FeedHelperProxyDelegate {
  func feedHelperConnectionWasInterrupted() {
    if isChecking {
      handleFeedCheckCompletion(wasSuccessful: false)
      NSLog("Feed helper service crashed")
    } else {
      NSLog("Feed helper service went offline")
    }
  }
}
