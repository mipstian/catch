import Foundation


struct HistoryItem {
  let title: String
  let url: URL
  let downloadDate: Date? // Very old items might not have a date set
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
