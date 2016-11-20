import Foundation


protocol SchedulerDelegate: class {
  func schedulerFired()
}


/// Periodically invokes its delegate
final class Scheduler {
  weak var delegate: SchedulerDelegate? = nil
  
  private var repeatingTimer: Timer! = nil
  
  /// Creates a scheduler with the specified interval.
  ///
  /// - Parameter interval: how long to wait between
  init(interval: TimeInterval) {
    repeatingTimer = Timer.scheduledTimer(
      timeInterval: interval,
      target: self,
      selector: #selector(timerFired),
      userInfo: nil,
      repeats: true
    )
  }
  
  deinit {
    repeatingTimer.invalidate()
  }
  
  /// Invoke the delegate immediately, and reset the timer
  /// (i.e. the next scheduled time will be after a full `interval`).
  func fireNow() {
    repeatingTimer.fireDate = .distantPast
  }
  
  @objc private func timerFired(_: Timer) {
    delegate?.schedulerFired()
  }
}
