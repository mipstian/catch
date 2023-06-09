import AppKit


@NSApplicationMain
final class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_: NSNotification) {
    // Enable Notification Center notifications
    NSUserNotificationCenter.defaultUserNotificationCenter().delegate = self
  }
  
  func applicationWillTerminate(_: NSNotification) {
    // Persist defaults before quitting
    CTCDefaults.save()
  }
}


extension AppDelegate: NSUserNotificationCenterDelegate {
  func userNotificationCenter(_: NSUserNotificationCenter, shouldPresentNotification _: NSUserNotification) -> Bool {
    return true
  }
}
