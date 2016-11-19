import Foundation


extension PropertyListSerialization {
  static func weblocData(from url: URL) throws -> Data {
    let weblocPlist = ["URL": url.absoluteString]
    
    return try PropertyListSerialization.data(
      fromPropertyList: weblocPlist,
      format: .binary,
      options: .allZeros
    )
  }
}
