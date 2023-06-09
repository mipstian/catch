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
    // Launch the system browser, open ShowRSS
    NSWorkspace.shared.open(.showRSSURL)
  }
  
  @IBAction private func browseWebsite(_: Any?) {
    // Launch the system browser, open the applications's website
    NSWorkspace.shared.open(.appURL)
  }
  
  @IBAction private func browseHelp(_: Any?) {
    // Launch the system browser, open the applications's on-line help
    NSWorkspace.shared.open(.helpURL)
  }
  
  @IBAction private func browseFeatureRequest(_: Any?) {
    // Launch the system browser, open the applications's feature request page
    NSWorkspace.shared.open(.featureRequestURL)
  }
  
  @IBAction private func browseBugReport(_: Any?) {
    // Launch the system browser, open the applications's bug report page
    NSWorkspace.shared.open(.bugReportURL)
  }
}
