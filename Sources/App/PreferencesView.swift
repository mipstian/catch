import AppKit


class PreferencesView: NSView {
  @IBOutlet weak var toolBar: NSToolbar!
  @IBOutlet weak var helpButton: NSButton!
  @IBOutlet weak var acceptButton: NSButton!
  
  @IBOutlet weak var importFromOPMLButton: NSButton!
  @IBOutlet weak var exportToOPMLButton: NSButton!
  @IBOutlet weak var onlyCheckBetweenCheckbox: NSButton!
  @IBOutlet weak var andLabel: NSTextField!
  
  @IBOutlet weak var saveToLabel: NSTextField!
  @IBOutlet weak var organizeCheckbox: NSButton!
  @IBOutlet weak var openAutomaticallyCheckbox: NSButton!
  @IBOutlet weak var downloadScriptCheckbox: NSButton!
  
  @IBOutlet weak var preventSleepCheckbox: NSButton!
  @IBOutlet weak var checkForUpdatesCheckbox: NSButton!
  @IBOutlet weak var openAtLoginButton: NSButton!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    for item in toolBar.items {
      item.label = NSLocalizedString(item.itemIdentifier.rawValue, comment: "")
    }
    helpButton.title = NSLocalizedString("Help Me Configure Catch", comment: "")
    acceptButton.title = NSLocalizedString("OK", comment: "")
    
    importFromOPMLButton.title = NSLocalizedString("Import From OPML File…", comment: "")
    exportToOPMLButton.title = NSLocalizedString("Export to OPML File…", comment: "")
    onlyCheckBetweenCheckbox.title = NSLocalizedString("Only check feed between", comment: "")
    andLabel.stringValue = NSLocalizedString("and", comment: "")
    
    saveToLabel.stringValue = NSLocalizedString("Save to:", comment: "")
    organizeCheckbox.title = NSLocalizedString("Organize in folders by show name", comment: "")
    openAutomaticallyCheckbox.title = NSLocalizedString("Open automatically", comment: "")
    downloadScriptCheckbox.title = NSLocalizedString("Download using script:", comment: "")
    
    preventSleepCheckbox.title = NSLocalizedString("Prevent system sleep when active", comment: "")
    checkForUpdatesCheckbox.title = NSLocalizedString("Automatically check for updates", comment: "")
    openAtLoginButton.title = NSLocalizedString("Open at Login", comment: "")
    
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
