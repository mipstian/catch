import Foundation


extension Bundle {
  var displayName: String { return infoDictionaryString(key: "CFBundleDisplayName") }
  var version: String { return infoDictionaryString(key: "CFBundleShortVersionString") }
  var buildNumber: String { return infoDictionaryString(key: "CFBundleVersion") }
  
  private func infoDictionaryString(key: String) -> String {
    return object(forInfoDictionaryKey: key) as! String
  }
}
