import AppKit


@NSApplicationMain
final class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_: Notification) {
    // Enable Notification Center notifications
    NSUserNotificationCenter.default.delegate = self
    
    PowerManager.shared.startMonitoring()
  }
  
  func applicationWillTerminate(_: Notification) {
    // Persist defaults before quitting
    Defaults.shared.save()
  }
}


extension AppDelegate: NSUserNotificationCenterDelegate {
  func userNotificationCenter(_: NSUserNotificationCenter, shouldPresent _: NSUserNotification) -> Bool {
    return true
  }
}


// MARK: Actions
extension AppDelegate {
  @IBAction private func browseShowRSS(_: Any?) {
    NSWorkspace.shared.open(.showRSSURL)
  }
  
  @IBAction private func browseWebsite(_: Any?) {
    NSWorkspace.shared.open(.appURL)
  }
  
  @IBAction private func browseHelp(_: Any?) {
    NSWorkspace.shared.open(.helpURL)
  }
  
  @IBAction private func browseOpenAtLoginHelp(_: Any?) {
    NSWorkspace.shared.open(.openAtLoginHelpURL)
  }
  
  @IBAction private func browseFeatureRequest(_: Any?) {
    NSWorkspace.shared.open(.featureRequestURL)
  }
  
  @IBAction private func browseBugReport(_: Any?) {
    NSWorkspace.shared.open(.bugReportURL)
  }
}
