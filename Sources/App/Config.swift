import Foundation


/// Static configuration parameters
enum Config {
  /// How often to check feeds
  static let feedUpdateInterval: TimeInterval = 60 * 10

  /// How much leeway to give to the os for scheduling
  static let feedUpdateIntervalTolerance: TimeInterval = 30
}
