import Foundation


class Defaults {
  static let shared = Defaults()
  private static let feedURLRegex = try! NSRegularExpression(
    pattern: "^https?://([^.]+\\.)*showrss.info/(.*)$"
  )
  
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
  
  var feedURL: String {
    let rawValue = UserDefaults.standard.string(forKey: Keys.feedURL)
    return rawValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
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
  
  var shouldOrganizeTorrentsInFolders: Bool {
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
    let feedURLMatches = Defaults.feedURLRegex.firstMatch(
      in: feedURL,
      options: [],
      range: NSMakeRange(0, feedURL.characters.count)
    )
    guard feedURLMatches != nil else {
      // The URL should match the regex
      NSLog("Feed URL (\(feedURL)) does not match regex")
      return false
    }
    guard feedURL.contains("namespaces") else {
      // The URL should have the namespaces parameter set
      NSLog("Feed URL does not have namespaces enabled")
      return false
    }
    
    return true
  }
  
  func save() {
    UserDefaults.standard.synchronize()
  }
  
  func refreshLoginItemStatus() {
    let shouldOpenAtLogin = UserDefaults.standard.bool(forKey: Keys.openAtLogin)
    Bundle.main.isLoginItem = shouldOpenAtLogin
  }
  
  private init() {
    // Create two dummy times (dates actually), just to have some value set
    let dateFrom = Calendar.current.date(from: DateComponents(hour: 24, minute: 0))!
    let dateTo = Calendar.current.date(from: DateComponents(hour: 8, minute: 0))!
    
    // Use user's Downloads directory as a default, fallback on home
    let defaultDownloadsDirectory = CTCFileUtils.userDownloadsDirectory() ?? CTCFileUtils.userHomeDirectory()
    NSLog("Default downloads directory is \(defaultDownloadsDirectory)")
    
    // Set smart default defaults
    UserDefaults.standard.register(
      defaults: [
        Keys.feedURL: "",
        Keys.onlyUpdateBetween: false,
        Keys.updateFrom: dateFrom,
        Keys.updateTo: dateTo,
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
          title: CTCFileUtils.filename(from: url),
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
