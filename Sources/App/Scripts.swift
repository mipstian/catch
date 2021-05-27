import Foundation
import os


extension Process {
  static func runDownloadScript(url: URL, completion: ((Bool) -> ())? = nil) {
    if Defaults.shared.isDownloadScriptEnabled, let downloadScriptPath = Defaults.shared.downloadScriptPath {
      os_log("Running download script", log: .main, type: .info)
      
      let script = Process()
      script.launchPath = downloadScriptPath.path
      script.arguments = [url.absoluteString]
      script.terminationHandler = { process in
        DispatchQueue.main.async {
          let success = process.terminationStatus == 0
          completion?(success)
          
          if !success {
            os_log("Script termination status: %d", log: .main, type: .error, process.terminationStatus)
          }
        }
      }
      script.launch()
    }
  }
}
