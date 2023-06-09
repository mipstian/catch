import Foundation


/// A previously downloaded episode. These are called "Recent episodes" in the UI.
struct HistoryItem {
  let title: String
  let url: URL
  
  /// When this episode was downloaded.
  ///
  /// - Note: Very old items might not have a date set.
  let downloadDate: Date?
  
  let isMagnetLink: Bool
}


extension HistoryItem {
  var dictionaryRepresentation: [AnyHashable:Any] {
    var dictionary: [AnyHashable:Any] = [
      "title": title,
      "url": url.absoluteString,
      "isMagnetLink": isMagnetLink
    ]
    if let downloadDate = downloadDate {
      dictionary["date"] = downloadDate
    }
    return dictionary
  }
}
