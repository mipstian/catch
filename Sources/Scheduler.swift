import Foundation


class Scheduler {
  static let statusChangedNotification = NSNotification.Name("scheduler-status-changed")
  static let shared = Scheduler()
  
  private static let xpcServiceName = "com.giorgiocalderolla.Catch.CatchFeedHelper"
  
  private(set) var isPolling = true { didSet { refreshActivity(); sendStatusChangedNotification() } }
  private(set) var isChecking = false { didSet { sendStatusChangedNotification() } }
  
  /// True iff the last feed check succeeded, or if no check has been made yet.
  private(set) var lastUpdateWasSuccessful = true
  
  /// The date/time of the last feed check, nil if no check has been made yet.
  private(set) var lastUpdateDate: Date? = nil
  
  private var shouldCheckNow: Bool {
    if !CTCDefaults.areTimeRestrictionsEnabled() { return true }
    
    return NSDate().isTime(
      ofDayBetweenDate: CTCDefaults.fromDateForTimeRestrictions(),
      andDate: CTCDefaults.toDateForTimeRestrictions()
    )
  }
  
  private var downloadFolderBookmark: Data {
    let url = URL(fileURLWithPath: CTCDefaults.torrentsSavePath())
    
    // Create a bookmark so we can transfer access to the downloads path
    // to the feed checker service
    return try! CTCFileUtils.bookmark(for: url)
  }
  
  private var repeatingTimer: Timer! = nil
  private let feedCheckerConnection = NSXPCConnection(serviceName: xpcServiceName)
  private var activityToken: NSObjectProtocol? = nil
  
  private init() {
    // Create and start single connection to the feed helper
    // Messages will be delivered serially
    feedCheckerConnection.remoteObjectInterface = NSXPCInterface(with: CTCFeedCheck.self)
    feedCheckerConnection.interruptionHandler = { [weak self] in
      DispatchQueue.main.async {
        guard let scheduler = self else { return }
  
        if scheduler.isChecking {
          scheduler.handleFeedCheckCompletion(wasSuccessful: false)
          NSLog("Feed checker service crashed")
        } else {
          NSLog("Feed checker service went offline")
        }
      }
    }
    feedCheckerConnection.resume()
    
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
    if !isPolling { return }
    
    // Prevent App Nap (so we can keep checking the feed), and optionally system sleep
    activityToken = ProcessInfo.processInfo.beginActivity(
      options: CTCDefaults.shouldPreventSystemSleep() ?
        [.suddenTerminationDisabled, .idleSystemSleepDisabled] :
        .suddenTerminationDisabled,
      reason: "Actively polling the feed"
    )
  }
  
  func downloadFile(_ file: [String:Any], completion: @escaping (([String:Any]?, Error?) -> ())) {
    // Call feed checker service
    let feedChecker = feedCheckerConnection.remoteObjectProxy as! CTCFeedCheck
    
    feedChecker.downloadFile(
      file,
      toBookmark: downloadFolderBookmark,
      organizingByFolder: CTCDefaults.shouldOrganizeTorrentsInFolders(),
      savingMagnetLinks: !CTCDefaults.shouldOpenTorrentsAutomatically(),
      withReply: { downloadedFile, error in
        if let error = error {
          NSLog("Feed Checker error (downloading file): \(error)")
        }
        DispatchQueue.main.async {
          completion(downloadedFile as? [String:Any], error)
        }
      }
    )
  }
  
  private func checkFeed() {
    // Don't check twice simultaneously
    if isChecking { return }
    
    // Only work with valid preferences
    guard CTCDefaults.isConfigurationValid() else {
      NSLog("Refusing to check feed - invalid preferences")
      return
    }
    
    isChecking = true
    
    // Check the feed
    callFeedCheckerWithReplyHandler { [weak self] (downloadedFeedFiles, error) in
      // Deal with new files
      self?.handleDownloadedFeedFiles(downloadedFeedFiles!) // TODO: nullability specifier
      self?.handleFeedCheckCompletion(wasSuccessful: error == nil)
    }
  }
  
  private func callFeedCheckerWithReplyHandler(replyHandler: @escaping CTCFeedCheckCompletionHandler) {
    // Read configuration
    let feedURL = URL(string: CTCDefaults.feedURL())!
    
    let history = CTCDefaults.downloadHistory()
    
    // Extract URLs from history
    let previouslyDownloadedURLs = history.map { $0["url"] as! String }
    
    // Call feed checker service
    let feedChecker = feedCheckerConnection.remoteObjectProxy as! CTCFeedCheck
    
    feedChecker.checkShowRSSFeed(
      feedURL,
      downloadingToBookmark: downloadFolderBookmark,
      organizingByFolder: CTCDefaults.shouldOrganizeTorrentsInFolders(),
      savingMagnetLinks: !CTCDefaults.shouldOpenTorrentsAutomatically(),
      skippingURLs: previouslyDownloadedURLs,
      withReply: { downloadedFeedFiles, error in
        if let error = error {
          NSLog("Feed Checker error (checking feed): \(error)")
        }
        DispatchQueue.main.async {
          replyHandler(downloadedFeedFiles, error)
        }
      }
    )
  }
  
  private func handleDownloadedFeedFiles(_ downloadedFeedFiles: [[AnyHashable : Any]]) {
    let shouldOpenTorrentsAutomatically = CTCDefaults.shouldOpenTorrentsAutomatically()
    
    for feedFile in downloadedFeedFiles.reversed() {
      let isMagnetLink = (feedFile["isMagnetLink"] as? NSNumber)?.boolValue ?? false
      
      // Open magnet link, if requested
      if isMagnetLink && shouldOpenTorrentsAutomatically {
        Browser.openInBackground(url: URL(string: feedFile["url"] as! String)!)
      }
      
      let torrentFilePath = feedFile["torrentFilePath"] as! String
      
      // Open normal torrent in torrent client, if requested
      if !isMagnetLink && shouldOpenTorrentsAutomatically {
        Browser.openInBackground(file: torrentFilePath)
      }
      
      let title = feedFile["title"] as! String
      
      postUserNotificationForNewEpisode(episodeTitle: title)
      
      let url = feedFile["url"] as! String
      
      // Add url to history
      var history = CTCDefaults.downloadHistory()
      history.append([
        "title": title,
        "url": url,
        "isMagnetLink": isMagnetLink,
        "date": Date()
      ])
      CTCDefaults.setDownloadHistory(history)
    }
  }
  
  private func postUserNotificationForNewEpisode(episodeTitle: String) {
    // Post to Notification Center
    let notification = NSUserNotification()
    notification.title = NSLocalizedString("newtorrent", comment: "New torrent notification")
    notification.informativeText = String(format: NSLocalizedString("newtorrentdesc", comment: "New torrent notification"), episodeTitle)
    notification.soundName = NSUserNotificationDefaultSoundName
    NSUserNotificationCenter.default.deliver(notification)
  }

  private func handleFeedCheckCompletion(wasSuccessful: Bool) {
    isChecking = false
    lastUpdateWasSuccessful = wasSuccessful
    lastUpdateDate = Date()
    
    sendStatusChangedNotification()
  }

  @objc private func tick(_ timer: Timer) {
    guard isPolling else { return }
    
    // Don't check if current time is outside user-defined range
    guard shouldCheckNow else { return }
    
    checkFeed()
  }
  
  private func fireTimerNow() {
    repeatingTimer.fireDate = Date.distantPast
  }
  
  private func sendStatusChangedNotification() {
    NotificationCenter.default.post(name: Scheduler.statusChangedNotification, object: self)
  }
}
