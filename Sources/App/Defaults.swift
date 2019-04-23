import Foundation


/// Singleton. Wrapper around UserDefaults.standard that provides a nice interface to the app's preferences
/// and download history data.
final class Defaults: NSObject {
  static let shared = Defaults()
  
  /// Posted whenever any default changes
  static let changedNotification = NSNotification.Name("Defaults.changedNotification")
  
  /// Posted whenever `downloadHistory` changes
  static let downloadHistoryChangedNotification = NSNotification.Name("Defaults.downloadHistoryChangedNotification")
  
  private struct Keys {
    static let feeds = "feeds"
    static let onlyUpdateBetween = "onlyUpdateBetween"
    static let updateFrom = "updateFrom"
    static let updateTo = "updateTo"
    static let torrentsSavePath = "savePath"
    static let shouldOrganizeTorrents = "organizeTorrents"
    static let shouldOpenTorrentsAutomatically = "openAutomatically"
    static let history = "history"
    static let openAtLogin = "openAtLogin"
    static let shouldRunHeadless = "headless"
    static let preventSystemSleep = "preventSystemSleep"
    static let downloadScriptPath = "downloadScriptPath"
    static let downloadScriptEnabled = "downloadScriptEnabled"
  }
  
  var feeds: [Feed] {
    get {
      let rawFeeds = UserDefaults.standard.array(forKey: Keys.feeds) as! [[AnyHashable:Any]]
      return rawFeeds.compactMap { return Feed(dictionary: $0) }
    }
    set {
      UserDefaults.standard.set(newValue.removingDuplicates().map { $0.dictionaryRepresentation }, forKey: Keys.feeds)
    }
  }
  
  var areTimeRestrictionsEnabled: Bool {
    return UserDefaults.standard.bool(forKey: Keys.onlyUpdateBetween)
  }
  
  var fromDateForTimeRestrictions: Date {
    return UserDefaults.standard.object(forKey: Keys.updateFrom) as! Date
  }
  
  var toDateForTimeRestrictions: Date {
    return UserDefaults.standard.object(forKey: Keys.updateTo) as! Date
  }
  
  var shouldOrganizeTorrentsByShow: Bool {
    return UserDefaults.standard.bool(forKey: Keys.shouldOrganizeTorrents)
  }
  
  var shouldOpenTorrentsAutomatically: Bool {
    return UserDefaults.standard.bool(forKey: Keys.shouldOpenTorrentsAutomatically)
  }
  
  var torrentsSavePath: URL? {
    guard let rawValue = UserDefaults.standard.string(forKey: Keys.torrentsSavePath) else {
      return nil
    }
    let expanded = NSString(string: rawValue).expandingTildeInPath
    return URL(fileURLWithPath: expanded).standardizedFileURL
  }
  
  var downloadScriptPath: URL? {
    get {
      guard let rawValue = UserDefaults.standard.string(forKey: Keys.downloadScriptPath) else {
        return nil
      }
      let expanded = NSString(string: rawValue).expandingTildeInPath
      return URL(fileURLWithPath: expanded).standardizedFileURL
    }
    set {
      let rawValue = newValue?.absoluteString
      UserDefaults.standard.set(rawValue, forKey: Keys.downloadScriptPath)
    }
  }
  
  var downloadScriptEnabled: Bool {
    return UserDefaults.standard.bool(forKey: Keys.downloadScriptEnabled)
  }
  
  /// Recently downloaded episodes. Remembered so they won't be downloaded again
  /// every time feeds are checked. They are presented in the UI as well.
  var downloadHistory: [HistoryItem] {
    get {
      let rawHistory = UserDefaults.standard.array(forKey: Keys.history) as! [[AnyHashable:Any]]
      return rawHistory.compactMap(HistoryItem.init(defaultsDictionary:))
    }
    set {
      // Only keep the most recent items
      let truncatedCount = min(newValue.count, Config.historyLimit * feeds.count)
      let truncatedHistory = newValue.sorted().reversed().prefix(upTo: truncatedCount)
      
      let serializedHistory = truncatedHistory.map { $0.dictionaryRepresentation }
      UserDefaults.standard.set(serializedHistory, forKey: Keys.history)
      
      NotificationCenter.default.post(
        name: Defaults.downloadHistoryChangedNotification,
        object: self
      )
    }
  }
  
  var shouldRunHeadless: Bool {
    return UserDefaults.standard.bool(forKey: Keys.shouldRunHeadless)
  }
  
  var shouldPreventSystemSleep: Bool {
    return UserDefaults.standard.bool(forKey: Keys.preventSystemSleep)
  }
  
  var isConfigurationValid: Bool {
    return hasValidFeeds
  }
  
  var isTorrentsSavePathValid: Bool {
    return torrentsSavePath?.isWritableDirectory ?? false
  }
  
  var hasValidFeeds: Bool {
    return feeds.count > 0
  }
  
  var hasShowRSSFeeds: Bool {
    return feeds.contains { $0.url.isShowRSSFeed }
  }
  
  var downloadOptions: DownloadOptions? {
    guard let torrentsSavePath = torrentsSavePath else { return nil }
    
    return DownloadOptions(
      containerDirectory: torrentsSavePath,
      shouldOrganizeByShow: shouldOrganizeTorrentsByShow,
      shouldSaveMagnetLinks: !shouldOpenTorrentsAutomatically
    )
  }
  
  func restricts(date: Date) -> Bool {
    if !areTimeRestrictionsEnabled { return false }
    
    return !date.isTimeOfDayBetween(
      startTimeOfDay: fromDateForTimeRestrictions,
      endTimeOfDay: toDateForTimeRestrictions
    )
  }
  
  func save() {
    UserDefaults.standard.synchronize()
  }
  
  private func refreshLoginItemStatus() {
    #if !DEBUG
      let shouldOpenAtLogin = UserDefaults.standard.bool(forKey: Keys.openAtLogin)
      Bundle.main.isLoginItem = shouldOpenAtLogin
    #endif
  }
  
  private override init() {
    super.init()
    
    // Default values for time restrictions
    let defaultFromTime = Calendar.current.date(from: DateComponents(hour: 24, minute: 0))!
    let defaultToTime = Calendar.current.date(from: DateComponents(hour: 8, minute: 0))!
    
    // Use user's Downloads directory as a default, fallback on home
    let defaultDownloadsDirectory = FileManager.default.downloadsDirectory ??
      FileManager.default.homeDirectory
    
    // Set smart default defaults
    let defaultDefaults: [String:Any] = [
      Keys.feeds: [],
      Keys.onlyUpdateBetween: false,
      Keys.updateFrom: defaultFromTime,
      Keys.updateTo: defaultToTime,
      Keys.torrentsSavePath: defaultDownloadsDirectory,
      Keys.shouldOrganizeTorrents: false,
      Keys.shouldOpenTorrentsAutomatically: true,
      Keys.history: [],
      Keys.openAtLogin: true,
      Keys.shouldRunHeadless: false,
      Keys.preventSystemSleep: true,
      Keys.downloadScriptEnabled: false
    ]
    UserDefaults.standard.register(defaults: defaultDefaults)
    
    // Migrate from single-feed to multi-feed
    if let legacyFeedURLString = UserDefaults.standard.string(forKey: "feedURL") {
      NSLog("Migrating feed URLs defaults")
      UserDefaults.standard.set(nil, forKey: "feedURL")
      if let legacyFeedURL = URL(string: legacyFeedURLString) {
        feeds.append(Feed(name: "ShowRSS", url: legacyFeedURL))
      }
    }
    
    // Observe changes for all keys
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(defaultsChanged),
      name: UserDefaults.didChangeNotification,
      object: nil
    )
    
    // Register as a login item if needed
    refreshLoginItemStatus()
  }
  
  @objc private func defaultsChanged(_: Notification) {
    NotificationCenter.default.post(
      name: Defaults.changedNotification,
      object: self
    )
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}


private extension HistoryItem {
  init?(defaultsDictionary: [AnyHashable:Any]) {
    guard
      let episode = Episode(dictionary: defaultsDictionary)
    else {
      return nil
    }
    
    self.episode = episode
    self.downloadDate = defaultsDictionary["date"] as? Date
  }
}


extension Collection where Element: Hashable {
  func removingDuplicates() -> [Element] {
    var set = Set<Element>()
    return compactMap { set.insert($0).inserted ? $0 : nil }
  }
}
