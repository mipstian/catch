import Foundation


/// Static configuration parameters.
enum Config {
  /// How often to check feeds.
  static let feedUpdateInterval: TimeInterval = 60 * 10

  /// How much leeway to give to the os for scheduling.
  static let feedUpdateIntervalTolerance: TimeInterval = 30
  
  /// Maximum number of episodes to keep in the download history.
  ///
  /// - SeeAlso: `downloadHistory` in `Defaults`
  /// - Note: this should be always higher than the number of episodes in a feed,
  ///         otherwise we'd end up re-downloading episodes over and over.
  static let historyLimit = 200
}
