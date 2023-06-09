import AppKit


class AddFeedView: NSView {
  @IBOutlet weak var feedNameField: NSTextField!
  
  @IBOutlet weak var addButton: NSButton!
  @IBOutlet weak var cancelButton: NSButton!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    feedNameField.placeholderString = NSLocalizedString("Feed Name", comment: "")

    addButton.title = NSLocalizedString("Add Feed", comment: "")
    cancelButton.title = NSLocalizedString("Cancel", comment: "")
  }
}
