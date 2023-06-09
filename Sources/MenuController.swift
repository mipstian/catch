import AppKit


class MenuController: NSObject {
  @IBOutlet private weak var menu: NSMenu!
  @IBOutlet private weak var menuVersion: NSMenuItem!
  @IBOutlet private weak var menuPauseResume: NSMenuItem!
  @IBOutlet private weak var menuLastUpdate: NSMenuItem!
  
  private var menuBarItem: NSStatusItem!
  
  private let lastUpdateDateFormatter = DateFormatter()

  override func awakeFromNib() {
    // Skip setup if we're running headless
    guard !CTCDefaults.shouldRunHeadless() else { return }
    
    // Create a date formatter for "last update" dates
    lastUpdateDateFormatter.timeStyle = .short
    
    // Create the NSStatusItem and set its length
    menuBarItem = NSStatusBar.system().statusItem(withLength: NSSquareStatusItemLength)
    
    // Tell the NSStatusItem what menu to load
    menuBarItem.menu = menu
    
    // Enable highlighting
    menuBarItem.highlightMode = true
    
    // Set current name and version
    menuVersion.title = "\(CTCDefaults.appName()) \(CTCDefaults.appVersion()) (\(CTCDefaults.buildNumber()))"
    
    // Update UI whenever the scheduler status changes
    NotificationCenter.default.addObserver(
      forName: Scheduler.statusChangedNotification,
      object: Scheduler.shared,
      queue: nil,
      using: { [weak self] _ in
        self?.refreshMenuContents()
      }
    )
    
    // Update UI now
    refreshMenuContents()
  }
  
  private func refreshMenuContents() {
    let isChecking = Scheduler.shared.isChecking
    let isPolling = Scheduler.shared.isPolling
    
    // Configure the menubar item's button
    let menuBarButtonTemplateImage: NSImage
    let menuBarButtonAppearsDisabled: Bool
    
    switch (isChecking, isPolling) {
    case (true, _):
      // Refreshing in progress (whether paused or not)
      menuBarButtonTemplateImage = #imageLiteral(resourceName: "Menubar_Refreshing_Template")
      menuBarButtonAppearsDisabled = false
    case (false, true):
      // Active but not refreshing now
      menuBarButtonTemplateImage = #imageLiteral(resourceName: "Menubar_Idle_Template")
      menuBarButtonAppearsDisabled = false
    case (false, false):
      // Paused and not refreshing now
      menuBarButtonTemplateImage = #imageLiteral(resourceName: "Menubar_Disabled_Template")
      menuBarButtonAppearsDisabled = true
    }
    
    menuBarItem.button?.image = menuBarButtonTemplateImage
    menuBarItem.button?.appearsDisabled = menuBarButtonAppearsDisabled
    
    // Configure the pause/resume item
    menuPauseResume.title = !isChecking && !isPolling ?
      NSLocalizedString("resume", comment: "Description of resume action") :
      NSLocalizedString("pause", comment: "Description of pause action")
    
    // Configure the "last update" item
    // Example: "Last update: 3:45 AM"
    let lastUpdateDate = Scheduler.shared.lastUpdateDate
    
    let lastUpdateStatusFormat = Scheduler.shared.lastUpdateWasSuccessful ?
      NSLocalizedString("lastupdate", comment: "Title for the last update time") :
      NSLocalizedString("lastupdatefailed", comment: "Title for the last update time if it fails")
    
    let lastUpdateText: String
    if isChecking {
      lastUpdateText = NSLocalizedString("updatingnow", comment: "An update is in progress")
    } else {
      let lastDateString: String
      if let lastUpdateDate = lastUpdateDate {
        lastDateString = lastUpdateDateFormatter.string(from: lastUpdateDate)
      } else {
        lastDateString = NSLocalizedString("never", comment: "Never happened")
      }
      
      lastUpdateText = String(format: lastUpdateStatusFormat, lastDateString)
    }
    
    menuLastUpdate.title = lastUpdateText
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}


// MARK: Actions
extension MenuController {
  @IBAction private func checkNow(_ sender: Any?) {
    Scheduler.shared.forceCheck()
  }
  
  @IBAction private func togglePause(_ sender: Any?) {
    Scheduler.shared.togglePause()
  }
}
