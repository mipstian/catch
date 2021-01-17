import AppKit


class PreferencesView: NSView {
  @IBOutlet weak var toolBar: NSToolbar!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    if #available(OSX 11.0, *) {
      let symbolsByIdentifier: [NSToolbarItem.Identifier:String] = [
        .init("Feed"):      "tray.2",
        .init("Downloads"): "square.and.arrow.down",
        .init("Tweaks"):    "gearshape"
      ]
      
      for item in toolBar.items {
        if let symbolName = symbolsByIdentifier[item.itemIdentifier] {
          item.image = NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: nil
          )
        }
      }
    }
  }
}
