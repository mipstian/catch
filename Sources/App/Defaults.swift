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
    static let feedURL = "feedURL"
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
    static let runScript = "runScript"
    static let scriptPath = "scriptPath"
  }
  
  var feedURL: URL? {
    guard let rawValue = UserDefaults.standard.string(forKey: Keys.feedURL) else { return nil }
    return URL(string: rawValue.trimmingCharacters(in: .whitespacesAndNewlines))
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
  
  /// Recently downloaded episodes. Remembered so they won't be downloaded again
  /// every time feeds are checked. They are presented in the UI as well.
  var downloadHistory: [HistoryItem] {
    get {
      let rawHistory = UserDefaults.standard.array(forKey: Keys.history) as! [[AnyHashable:Any]]
      return rawHistory.compactMap(HistoryItem.init(defaultsDictionary:))
    }
    set {
      // Only keep the most recent items
      let truncatedCount = min(newValue.count, Config.historyLimit)
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
    let result = isFeedURLValid && (!runScript || (runScript && isScriptPathValid) )
    return result
  }
  
  var isTorrentsSavePathValid: Bool {
    guard let path = torrentsSavePath?.path else { return false }
    
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue else {
      // Download path does not exist or is not a directory
      return false
    }
    
    guard FileManager.default.isWritableFile(atPath: path) else {
      // Download path is not writable
      return false
    }
    
    return true
  }
    
  var isShowRSSFeed: Bool {
    guard
      let host = feedURL?.host,
      host.hasSuffix("showrss.info")
      else {
        return false
    }
    return true
  }
  
  var isFeedURLValid: Bool {
    guard
      let url = feedURL,
      let scheme = url.scheme
    else {
      return false
    }
    
    guard ["http", "https"].contains(scheme) else {
      NSLog("Bad scheme in feed URL: \(scheme)")
      return false
    }
    
    if isShowRSSFeed,
      let query = url.query,
      !query.contains("namespaces=true") {
        NSLog("Feed URL does not have namespaces enabled")
        return false
    }
    
    return true
  }
  
  var downloadOptions: DownloadOptions? {
    guard let torrentsSavePath = torrentsSavePath else { return nil }
    
    return DownloadOptions(
      containerDirectory: torrentsSavePath,
      shouldOrganizeByShow: shouldOrganizeTorrentsByShow,
      shouldSaveMagnetLinks: !shouldOpenTorrentsAutomatically
    )
  }
  
  var runScript: Bool {
    let result = UserDefaults.standard.bool(forKey: Keys.runScript)
    return result
  }
  
  var scriptPath: URL? {
    guard let rawValue = UserDefaults.standard.string(forKey: Keys.scriptPath) else {
      return nil
    }
    let expanded = NSString(string: rawValue).expandingTildeInPath
    return URL(fileURLWithPath: expanded).standardizedFileURL
  }
  
  var isScriptPathValid: Bool {
    guard let path = scriptPath?.path else { return false }

    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory), !isDirectory.boolValue else {
      // Download path does not exist or is a directory
      return false
    }
    
    guard FileManager.default.isExecutableFile(atPath: path) else {
      // Download path is not executable
      return false
    }
    
    return true
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
      Keys.feedURL: "",
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
      Keys.runScript: false,
      Keys.scriptPath: ""
    ]
    UserDefaults.standard.register(defaults: defaultDefaults)
    
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
      let title = defaultsDictionary["title"] as? String,
      let url = (defaultsDictionary["url"] as? String).flatMap(URL.init)
    else {
      return nil
    }
    
    self.episode = Episode(
      title: title,
      url: url,
      showName: defaultsDictionary["showName"] as? String
    )
    self.downloadDate = defaultsDictionary["date"] as? Date
  }
}
