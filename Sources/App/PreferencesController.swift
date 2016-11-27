import AppKit
import Sparkle


/// Manages the "Preferences" window.
class PreferencesController: NSWindowController {
  @IBOutlet private weak var feedURLWarningImageView: NSImageView!
  @IBOutlet private weak var torrentsSavePathWarningImageView: NSImageView!
  @IBOutlet private weak var automaticallyCheckForUpdatesCheckbox: NSButton!
  
  override func awakeFromNib() {
    // Bind automatically check for updates checkbox to sparkle
    #if !DEBUG
      automaticallyCheckForUpdatesCheckbox.bind(
        "value",
        to: SUUpdater.shared(),
        withKeyPath: "automaticallyChecksForUpdates"
      )
    #endif
    
    showFeeds(self)
    
    // If the configuration isn't valid, pop up immediately
    if !Defaults.shared.isConfigurationValid { showWindow(self) }
    
    // Update UI whenever relevant defaults change
    NotificationCenter.default.addObserver(
      forName: Defaults.changedNotification,
      object: Defaults.shared,
      queue: nil,
      using: { [weak self] notification in
        guard
          let changedKey = notification.userInfo?[Defaults.changedNotificationChangedKey] as? String,
          [Defaults.Keys.torrentsSavePath, Defaults.Keys.feedURL].contains(changedKey)
        else {
          return
        }
        self?.refreshInvalidInputMarkers()
      }
    )
  }
  
  fileprivate func refreshInvalidInputMarkers() {
    torrentsSavePathWarningImageView.image = Defaults.shared.isTorrentsSavePathValid ? #imageLiteral(resourceName: "success") : #imageLiteral(resourceName: "warning")
    feedURLWarningImageView.image = Defaults.shared.isFeedURLValid ? #imageLiteral(resourceName: "success") : #imageLiteral(resourceName: "warning")
  }
  
  deinit {
    automaticallyCheckForUpdatesCheckbox.unbind("value")
    NotificationCenter.default.removeObserver(self)
  }
}


// MARK: Actions
extension PreferencesController {
  @IBAction override func showWindow(_ sender: Any?) {
    refreshInvalidInputMarkers()
    NSApp.activate(ignoringOtherApps: true)
    super.showWindow(sender)
  }
  
  @IBAction private func savePreferences(_: Any?) {
    Defaults.shared.save()
    
    guard Defaults.shared.isConfigurationValid else {
      // Show the Feeds tab because all possible invalid inputs are currently there
      showFeeds(self)
      
      // Shake the window to signal invalid input
      window?.performShakeAnimation(duration: 0.3)
      
      return
    }
    
    // Hide the Preferences window
    window?.close()
    
    // Also force check
    FeedChecker.shared.forceCheck()
  }
  
  @IBAction fileprivate func showFeeds(_: Any?) {
    // Select the Feeds tab
    window?.toolbar?.selectedItemIdentifier = "Feed"
  }
  
  @IBAction private func showTweaks(_: Any?) {
    // Select the Tweaks tab
    window?.toolbar?.selectedItemIdentifier = "Tweaks"
  }
}
