import Foundation


extension Process {
  static func runDownloadScript(url: URL) {
    if Defaults.shared.downloadScriptEnabled, let downloadScriptPath = Defaults.shared.downloadScriptPath {
      Self.launchedProcess(
        launchPath: downloadScriptPath.path,
        arguments: [url.absoluteString]
      )
    }
  }
}
