import AppKit


private extension URL {
  static let showRSSURL = URL(string: "https://showrss.info/")!
  static let appURL = URL(string: "http://github.com/mipstian/catch")!
  static let bugReportURL = URL(string: "https://github.com/mipstian/catch/issues/new?labels=bug")!
  static let featureRequestURL = URL(string: "https://github.com/mipstian/catch/issues/new?labels=enhancement")!
  static let helpURL = URL(string: "https://github.com/mipstian/catch/wiki/Configuration")!
}


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
    // Launch the system browser, open ShowRSS
    NSWorkspace.shared().open(.showRSSURL)
  }
  
  @IBAction private func browseWebsite(_: Any?) {
    // Launch the system browser, open the applications's website
    NSWorkspace.shared().open(.appURL)
  }
  
  @IBAction private func browseHelp(_: Any?) {
    // Launch the system browser, open the applications's on-line help
    NSWorkspace.shared().open(.helpURL)
  }
  
  @IBAction private func browseFeatureRequest(_: Any?) {
    // Launch the system browser, open the applications's feature request page
    NSWorkspace.shared().open(.featureRequestURL)
  }
  
  @IBAction private func browseBugReport(_: Any?) {
    // Launch the system browser, open the applications's bug report page
    NSWorkspace.shared().open(.bugReportURL)
  }
}
