import AppKit


/// Manages the "Add Feed" window (run as a sheet)
class AddFeedController: NSWindowController {
  @IBOutlet private weak var feedNameTextField: NSTextField!
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
  
  func clear() {
    feedNameTextField.stringValue = ""
    feedURLTextField.stringValue = ""
  }
}


// MARK: Actions
extension AddFeedController {
  @IBAction private func add(_ sender: Any?) {
    let feedName = feedNameTextField.stringValue
    
    guard
      feedName != "",
      let feedURL = URL(string: feedURLTextField.stringValue),
      feedURL.isValidFeedURL
    else {
      return
    }
    
    let newFeed = Feed(name: feedName, url: feedURL)
    
    Defaults.shared.feeds.append(newFeed)
    
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
