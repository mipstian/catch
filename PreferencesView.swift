import AppKit


class PreferencesView: NSView {
  @IBOutlet weak var toolBar: NSToolbar!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    for item in toolBar.items {
      item.label = NSLocalizedString(item.itemIdentifier.rawValue, comment: "")
    }
    
    if #available(OSX 11.0, *) {
      let symbolsByIdentifier: [String:String] = [
        "Feeds":     "tray.2",
        "Downloads": "square.and.arrow.down",
        "Tweaks":    "gearshape"
      ]
      
      for item in toolBar.items {
        if let symbolName = symbolsByIdentifier[item.itemIdentifier.rawValue] {
          
          item.image = NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: nil
          )
        }
      }
    }
  }
}
