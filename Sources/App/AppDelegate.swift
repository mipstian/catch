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
