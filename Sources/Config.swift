import Foundation


/// A wrapper for accessing Info.plist values
enum Config {
  static let appName = infoString(key: "CFBundleDisplayName")
  static let appVersion = infoString(key: "CFBundleShortVersionString")
  static let buildNumber = infoString(key: "CFBundleVersion")
  
  private static func infoString(key: String) -> String {
    return Bundle.main.object(forInfoDictionaryKey: key) as! String
  }
}
