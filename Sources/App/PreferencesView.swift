import AppKit


class PreferencesView: NSView {
  @IBOutlet weak var importFromOPMLButton: NSButton!
  
  @IBOutlet weak var saveToLabel: NSTextField!
  @IBOutlet weak var organizeCheckbox: NSButton!
  @IBOutlet weak var openAutomaticallyCheckbox: NSButton!
  @IBOutlet weak var downloadScriptCheckbox: NSButton!
  
  @IBOutlet weak var toolBar: NSToolbar!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    importFromOPMLButton.title = NSLocalizedString("Import From OPML File…", comment: "")
    
    saveToLabel.stringValue = NSLocalizedString("Save to:", comment: "")
    organizeCheckbox.title = NSLocalizedString("Organize in folders by show name", comment: "")
    openAutomaticallyCheckbox.title = NSLocalizedString("Open automatically", comment: "")
    downloadScriptCheckbox.title = NSLocalizedString("Download using script:", comment: "")
    
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
