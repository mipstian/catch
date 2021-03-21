import Foundation


extension Process {
  static func runDownloadScript(url: URL, completion: ((Bool) -> ())? = nil) {
    if Defaults.shared.isDownloadScriptEnabled, let downloadScriptPath = Defaults.shared.downloadScriptPath {
      NSLog("Running download script")
      
      let script = Process()
      script.launchPath = downloadScriptPath.path
      script.arguments = [url.absoluteString]
      script.terminationHandler = { process in
        DispatchQueue.main.async {
          let success = process.terminationStatus == 0
          completion?(success)
          
          if !success {
            NSLog("Script termination status: \(process.terminationStatus)")
          }
        }
      }
      script.launch()
    }
  }
}
