import AppKit


/// Manages the app's menu and status item in the menubar.
class MenuController: NSObject {
  @IBOutlet private weak var menu: NSMenu!
  @IBOutlet private weak var menuVersion: NSMenuItem!
  @IBOutlet private weak var menuPauseResume: NSMenuItem!
  @IBOutlet private weak var menuLastUpdate: NSMenuItem!
  @IBOutlet private weak var menuLaunchShowRSS: NSMenuItem!
  @IBOutlet private weak var menuTopSeparator: NSMenuItem!

  private var menuBarItem: NSStatusItem!

  override func awakeFromNib() {
    // Skip setup if we're running headless
    guard !Defaults.shared.shouldRunHeadless else { return }
    
    // Create the NSStatusItem and set its length
    menuBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    
    // Tell the NSStatusItem what menu to load
    menuBarItem.menu = menu
    
    // Enable highlighting
    menuBarItem.highlightMode = true
    
    // Set current name and version
    let bundle = Bundle.main
    menuVersion.title = "\(bundle.displayName) \(bundle.version) (\(bundle.buildNumber))"
    
    #if DEBUG
      menuVersion.title = "[DEBUG] " + menuVersion.title
    #endif
    
    // Update UI whenever the feed checker status changes
    NotificationCenter.default.addObserver(
      forName: FeedChecker.stateChangedNotification,
      object: FeedChecker.shared,
      queue: nil,
      using: { [weak self] _ in
        self?.refreshMenuContents()
      }
    )
    
    NotificationCenter.default.addObserver(
      forName: Defaults.changedNotification,
      object: Defaults.shared,
      queue: nil,
      using: { [weak self] _ in
        self?.refreshMenuContents()
      }
    )
    
    // Update UI now
    refreshMenuContents()
  }
  
  private func refreshMenuContents() {
    // Configure the menubar item's button
    let menuBarButtonTemplateImage: NSImage
    let menuBarButtonAppearsDisabled: Bool
    switch (FeedChecker.shared.lastCheckStatus, FeedChecker.shared.status) {
    case (.inProgress, _):
      // Refreshing in progress (whether paused or not)
      menuBarButtonTemplateImage = #imageLiteral(resourceName: "Menubar_Refreshing_Template")
      menuBarButtonAppearsDisabled = false
    case (_, .polling):
      // Active but not refreshing now
      menuBarButtonTemplateImage = #imageLiteral(resourceName: "Menubar_Idle_Template")
      menuBarButtonAppearsDisabled = false
    case (_, .paused):
      // Paused and not refreshing now
      menuBarButtonTemplateImage = #imageLiteral(resourceName: "Menubar_Disabled_Template")
      menuBarButtonAppearsDisabled = true
    }
    
    menuBarItem.button?.image = menuBarButtonTemplateImage
    menuBarItem.button?.appearsDisabled = menuBarButtonAppearsDisabled
    
    // Configure the pause/resume item
    let pauseResumeItemTitle: String
    switch FeedChecker.shared.status {
    case .polling:
      pauseResumeItemTitle = NSLocalizedString("pause", comment: "Description of pause action")
    case .paused:
      pauseResumeItemTitle = NSLocalizedString("resume", comment: "Description of resume action")
    }
    menuPauseResume.title = pauseResumeItemTitle
    
    // Configure the "last update" item
    menuLastUpdate.title = FeedChecker.shared.lastCheckStatus.localizedDescription
    
    menuLaunchShowRSS.isHidden = !Defaults.shared.isShowRSSFeed
    menuTopSeparator.isHidden = !Defaults.shared.isShowRSSFeed
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}


// MARK: Actions
extension MenuController {
  @IBAction private func checkNow(_ sender: Any?) {
    FeedChecker.shared.forceCheck()
  }
  
  @IBAction private func togglePause(_ sender: Any?) {
    switch FeedChecker.shared.status {
    case .paused: FeedChecker.shared.status = .polling
    case .polling: FeedChecker.shared.status = .paused
    }
  }
}


private extension FeedChecker.LastCheckStatus {
  /// User-readable description.
  /// Example: "Last update: 3:45 AM".
  var localizedDescription: String {
    let dateFormatter = DateFormatter()
    dateFormatter.timeStyle = .short
    
    let normalFormat = NSLocalizedString("lastupdate", comment: "Title for the last update time")
    let skippedFormat = NSLocalizedString("lastupdateskipped", comment: "Title for the last update time if it was skipped")
    let failedFormat = NSLocalizedString("lastupdatefailed", comment: "Title for the last update time if it fails")
    
    switch self {
    case .neverHappened:
      return String(format: normalFormat, NSLocalizedString("never", comment: "Never happened"))
    case .inProgress:
      return NSLocalizedString("updatingnow", comment: "An update is in progress")
    case .failed(let date, _):
      return String(format: failedFormat, dateFormatter.string(from: date))
    case .skipped(let date):
      return String(format: skippedFormat, dateFormatter.string(from: date))
    case .successful(let date):
      return String(format: normalFormat, dateFormatter.string(from: date))
    }
  }
}
