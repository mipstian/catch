import Foundation


protocol IntervalTimerDelegate: class {
  func timerFired()
}


/// Periodically invokes its delegate
final class IntervalTimer {
  weak var delegate: IntervalTimerDelegate? = nil
  
  private var repeatingTimer: Timer! = nil
  
  /// Creates a repeating timer with the specified interval.
  ///
  /// - Parameter interval: how long to wait between firing
  /// - Parameter tolerance: leeway for the os to schedule for energy efficiency
  init(interval: TimeInterval, tolerance: TimeInterval) {
    repeatingTimer = .scheduledTimer(
      timeInterval: interval,
      target: self,
      selector: #selector(timerFired),
      userInfo: nil,
      repeats: true
    )
    repeatingTimer.tolerance = tolerance
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
    delegate?.timerFired()
  }
}
