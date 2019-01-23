import AppKit


/// Manages the "Add Feed" window (run as a sheet)
class AddFeedController: NSWindowController {
  @IBOutlet private weak var feedURLTextField: NSTextField!
  @IBOutlet private weak var addButton: NSButton!
  
  override func awakeFromNib() {
    refresh()
  }
  
  private func refresh() {
    let feedURL = URL(string: feedURLTextField.stringValue)
    addButton.isEnabled = feedURL?.isValidFeedURL ?? false
  }
  
  private func dismiss() {
    guard let window = window else { return }
    
    window.sheetParent?.endSheet(window)
  }
}


// MARK: Actions
extension AddFeedController {
  @IBAction private func add(_ sender: Any?) {
    guard
      let feedURL = URL(string: feedURLTextField.stringValue),
      feedURL.isValidFeedURL
    else {
      return
    }
    
    Defaults.shared.feedURLs.append(feedURL)
    
    dismiss()
  }
  
  @IBAction private func cancel(_: Any?) {
    dismiss()
  }
}


extension AddFeedController: NSTextFieldDelegate {
  func controlTextDidChange(_ obj: Notification) {
    refresh()
  }
}
