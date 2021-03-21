import AppKit


extension NSWorkspace {
  func openInBackground(url: URL) {
    // Open a link without bringing the app that handles it to the foreground
    open(
      [url],
      withAppBundleIdentifier: nil,
      options: .withoutActivation,
      additionalEventParamDescriptor: nil,
      launchIdentifiers: nil
    )
  }
  
  func openInBackground(file: String) {
    // Open a file without bringing the app that handles it to the foreground
    openFile(file, withApplication: nil, andDeactivate: false)
  }
}
