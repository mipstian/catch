import Foundation


/// Singleton. Listens for changes in the app's state and configures App Nap and
/// system sleep accordingly.
final class PowerManager {
  static let shared = PowerManager()
  
  private init() {}
  
  private var activityToken: NSObjectProtocol? = nil
  
  /// Start listening for changes that affect power management.
  func startMonitoring() {
    NotificationCenter.default.addObserver(
      forName: FeedChecker.stateChangedNotification,
      object: FeedChecker.shared,
      queue: nil,
      using: { [weak self] _ in
        self?.refreshPowerManagement()
      }
    )
    
    // Listen for relevant Defaults changes.
    NotificationCenter.default.addObserver(
      forName: Defaults.changedNotification,
      object: Defaults.shared,
      queue: nil,
      using: { [weak self] notification in
        guard
          let changedKey = notification.userInfo?[Defaults.changedNotificationChangedKey] as? String,
          changedKey == Defaults.Keys.preventSystemSleep
        else {
          return
        }
        self?.refreshPowerManagement()
      }
    )
    
    refreshPowerManagement()
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  /// Makes the app's power management status (App Nap and system sleep) reflect the
  /// current app state and settings.
  private func refreshPowerManagement() {
    // End previously started activity if any
    if let token = activityToken {
      ProcessInfo.processInfo.endActivity(token)
      activityToken = nil
    }
    
    // No need to prevent App Nap or system sleep if paused
    guard FeedChecker.shared.status == .polling else { return }
    
    // Prevent App Nap (so we can keep checking the feed), and optionally system sleep
    activityToken = ProcessInfo.processInfo.beginActivity(
      options: Defaults.shared.shouldPreventSystemSleep ?
        [.suddenTerminationDisabled, .idleSystemSleepDisabled] :
        .suddenTerminationDisabled,
      reason: "Actively polling the feed"
    )
  }
}
