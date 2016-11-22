import Foundation


/// Wrapper around UserDefaults.standard that provides a nice interface to the app's preferences
/// and download history data.
final class Defaults {
  static let shared = Defaults()
  
  private struct Keys {
    static let feedURL = "feedURL"
    static let onlyUpdateBetween = "onlyUpdateBetween"
    static let updateFrom = "updateFrom"
    static let updateTo = "updateTo"
    static let torrentsSavePath = "savePath"
    static let shouldOrganizeTorrents = "organizeTorrents"
    static let shouldOpenTorrentsAutomatically = "openAutomatically"
    static let downloadedFiles = "downloadedFiles" // Deprecated, for migration only
    static let history = "history"
    static let openAtLogin = "openAtLogin"
    static let shouldRunHeadless = "headless"
    static let preventSystemSleep = "preventSystemSleep"
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
  
  var downloadHistory: [HistoryItem] {
    get {
      let rawHistory = UserDefaults.standard.array(forKey: Keys.history) as! [[AnyHashable:Any]]
      return rawHistory.flatMap(HistoryItem.init(defaultsDictionary:))
    }
    set {
      UserDefaults.standard.set(newValue.map { $0.dictionaryRepresentation }, forKey: Keys.history)
    }
  }
  
  var shouldRunHeadless: Bool {
    return UserDefaults.standard.bool(forKey: Keys.shouldRunHeadless)
  }
  
  var shouldPreventSystemSleep: Bool {
    return UserDefaults.standard.bool(forKey: Keys.preventSystemSleep)
  }
  
  var isConfigurationValid: Bool {
    return isTorrentsSavePathValid && isFeedURLValid
  }
  
  var isTorrentsSavePathValid: Bool {
    guard let path = torrentsSavePath?.path else { return false }
    
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue else {
      NSLog("Download path \(path) does not exist or is not a directory")
      return false
    }
    
    guard FileManager.default.isWritableFile(atPath: path) else {
      NSLog("Download path \(path) is not writable")
      return false
    }
    
    return true
  }
  
  var isFeedURLValid: Bool {
    guard
      let url = feedURL,
      let scheme = url.scheme,
      let host = url.host,
      let query = url.query
    else {
      return false
    }
    
    guard ["http", "https"].contains(scheme) else {
      NSLog("Bad scheme in feed URL: \(scheme)")
      return false
    }
    
    guard host.hasSuffix("showrss.info") else {
      NSLog("Bad host in feed URL: \(host)")
      return false
    }
    
    guard query.contains("namespaces=true") else {
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
  
  func refreshLoginItemStatus() {
    #if !DEBUG
      let shouldOpenAtLogin = UserDefaults.standard.bool(forKey: Keys.openAtLogin)
      Bundle.main.isLoginItem = shouldOpenAtLogin
    #endif
  }
  
  private init() {
    // Default values for time restrictions
    let timeFrom = Calendar.current.date(from: DateComponents(hour: 24, minute: 0))!
    let timeTo = Calendar.current.date(from: DateComponents(hour: 8, minute: 0))!
    
    // Use user's Downloads directory as a default, fallback on home
    let defaultDownloadsDirectory = FileUtils.userDownloadsDirectory ?? FileUtils.userHomeDirectory
    NSLog("Default downloads directory is \(defaultDownloadsDirectory)")
    
    // Set smart default defaults
    UserDefaults.standard.register(
      defaults: [
        Keys.feedURL: "",
        Keys.onlyUpdateBetween: false,
        Keys.updateFrom: timeFrom,
        Keys.updateTo: timeTo,
        Keys.torrentsSavePath: defaultDownloadsDirectory,
        Keys.shouldOrganizeTorrents: false,
        Keys.shouldOpenTorrentsAutomatically: true,
        Keys.openAtLogin: true,
        Keys.preventSystemSleep: true
      ]
    )
    
    // Migrate the downloads history format. Change old array of strings to new dictionary format
    let downloadedFiles = UserDefaults.standard.array(forKey: Keys.downloadedFiles) as? [String]
    let history = UserDefaults.standard.array(forKey: Keys.history)
    if let downloadedFiles = downloadedFiles, history == nil {
      NSLog("Migrating download history to new format.")
      
      downloadHistory = downloadedFiles.flatMap(URL.init(string:)).map { url in
        return HistoryItem(
          title: FileUtils.filename(from: url),
          url: url,
          downloadDate: nil,
          isMagnetLink: false
        )
      }
      
      UserDefaults.standard.removeObject(forKey: Keys.downloadedFiles)
    }
    
    // If history was never set or migrated, init it to empty array
    if downloadedFiles == nil && history == nil {
      downloadHistory = []
    }
    
    // Register as a login item if needed
    refreshLoginItemStatus()
  }
}


private extension HistoryItem {
  init?(defaultsDictionary: [AnyHashable:Any]) {
    guard let title = defaultsDictionary["title"] as? String,
      let url = (defaultsDictionary["url"] as? String).flatMap(URL.init) else {
        return nil
    }
    
    self.title = title
    self.url = url
    self.downloadDate = defaultsDictionary["date"] as? Date
    self.isMagnetLink = (defaultsDictionary["isMagnetLink"] as? NSNumber)?.boolValue ?? false
  }
}
