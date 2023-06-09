import Foundation


/// A previously downloaded episode. These are called "Recent episodes" in the UI.
struct HistoryItem {
  let episode: Episode
  
  /// When this episode was downloaded.
  ///
  /// - Note: Very old items might not have a date set.
  let downloadDate: Date?
}


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
