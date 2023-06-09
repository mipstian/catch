import AppKit


class Browser: NSObject {
  static func openInBackground(url: URL) {
    // Open a link without bringing app that handles it to the foreground
    NSWorkspace.shared().open(
      [url],
      withAppBundleIdentifier: nil,
      options: .withoutActivation,
      additionalEventParamDescriptor: nil,
      launchIdentifiers: nil
    )
  }
  
  static func openInBackground(file: String) {
    // Open a file without bringing app that handles it to the foreground
    NSWorkspace.shared().openFile(file, withApplication: nil, andDeactivate: false)
  }
}


// MARK: Actions
extension Browser {
  @IBAction private func browseService(_: Any?) {
    // Launch the system browser, open the service (ShowRSS)
    NSWorkspace.shared().open(URL(string: kCTCDefaultsServiceURL)!)
  }
  
  @IBAction private func browseWebsite(_: Any?) {
    // Launch the system browser, open the applications's website
    NSWorkspace.shared().open(URL(string: kCTCDefaultsApplicationWebsiteURL)!)
  }
  
  @IBAction private func browseHelp(_: Any?) {
    // Launch the system browser, open the applications's on-line help
    NSWorkspace.shared().open(URL(string: kCTCDefaultsApplicationHelpURL)!)
  }
  
  @IBAction private func browseFeatureRequest(_: Any?) {
    // Launch the system browser, open the applications's feature request page
    NSWorkspace.shared().open(URL(string: kCTCDefaultsApplicationFeatureRequestURL)!)
  }
  
  @IBAction private func browseBugReport(_: Any?) {
    // Launch the system browser, open the applications's bug report page
    NSWorkspace.shared().open(URL(string: kCTCDefaultsApplicationBugReportURL)!)
  }
}
