import AppKit


class RecentsCellView: NSTableCellView {
  @IBOutlet weak var downloadDateTextField: NSTextField!
  @IBOutlet weak var downloadAgainButton: NSButton!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    if #available(OSX 11.0, *) {
      downloadAgainButton.image = NSImage(
        systemSymbolName: "arrow.clockwise.circle.fill",
        accessibilityDescription: nil
      )?.withSymbolConfiguration(.init(scale: .large))
    }
  }
}
