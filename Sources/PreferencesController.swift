import AppKit


class PreferencesController: NSWindowController {
  @IBOutlet private weak var feedURLWarningImageView: NSImageView!
  @IBOutlet private weak var torrentsSavePathWarningImageView: NSImageView!
  
  override func awakeFromNib() {
    showFeeds(self)
    
    // If the configuration isn't valid, pop up immediately
    if !Defaults.shared.isConfigurationValid { showWindow(self) }
    
    // TODO: encapsulate this
    UserDefaults.standard.addObserver(self, forKeyPath: "savePath", options: .new, context: nil)
    UserDefaults.standard.addObserver(self, forKeyPath: "feedURL", options: .new, context: nil)
  }
  
  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey:Any]?, context: UnsafeMutableRawPointer?) {
    refreshInvalidInputMarkers()
  }
  
  fileprivate func refreshInvalidInputMarkers() {
    torrentsSavePathWarningImageView.image = Defaults.shared.isTorrentsSavePathValid ? #imageLiteral(resourceName: "success") : #imageLiteral(resourceName: "warning")
    feedURLWarningImageView.image = Defaults.shared.isFeedURLValid ? #imageLiteral(resourceName: "success") : #imageLiteral(resourceName: "warning")
  }
  
  deinit {
    UserDefaults.standard.removeObserver(self, forKeyPath: "savePath")
    UserDefaults.standard.removeObserver(self, forKeyPath: "feedURL")
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
    
    if Defaults.shared.isConfigurationValid {
      // Hide the Preferences window
      window?.close()
      
      // Apply the login item setting
      // TODO: move to defaults
      Defaults.shared.refreshLoginItemStatus()
      
      // Apply power management settings
      // TODO: move to scheduler
      Scheduler.shared.refreshActivity()
      
      // Also force check
      Scheduler.shared.forceCheck()
    }
    else {
      // Show the Feeds tab because all possible invalid inputs are currently there
      showFeeds(self)
      
      // Shake the window to signal invalid input
      window?.performShakeAnimation(duration: 0.3)
    }
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
