import Foundation


/// A previously downloaded episode. These are called "Recent episodes" in the UI.
struct HistoryItem {
  let episode: Episode
  
  /// When this episode was downloaded.
  ///
  /// - Note: Very old items might not have a date set.
  let downloadDate: Date?
}


extension HistoryItem: Equatable {
  static func ==(lhs: HistoryItem, rhs: HistoryItem) -> Bool {
    return lhs.episode == rhs.episode && lhs.downloadDate == rhs.downloadDate
  }
}


extension HistoryItem: Comparable {
  /// Cronological comparison
  ///
  /// - Note: Items with missing dates are considered older than every other item
  static func <(lhs: HistoryItem, rhs: HistoryItem) -> Bool {
    guard let lhsDate = lhs.downloadDate else { return true }
    guard let rhsDate = rhs.downloadDate else { return false }
    
    return lhsDate < rhsDate
  }
}


// MARK: Serialization
extension HistoryItem {
  var dictionaryRepresentation: [AnyHashable:Any] {
    var dictionary: [AnyHashable:Any] = [
      "title": episode.title,
      "url": episode.url.absoluteString
    ]
    if let showName = episode.showName {
      dictionary["showName"] = showName
    }
    if let downloadDate = downloadDate {
      dictionary["date"] = downloadDate
    }
    return dictionary
  }
}
