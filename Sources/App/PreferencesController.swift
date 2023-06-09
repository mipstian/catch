import AppKit
import Sparkle


private extension NSBindingName {
  static let checkboxValue = NSBindingName(rawValue: "value")
}

private extension NSUserInterfaceItemIdentifier {
  static let feedNameColumn = NSUserInterfaceItemIdentifier(rawValue: "FeedNameColumn")
  static let feedURLColumn = NSUserInterfaceItemIdentifier(rawValue: "FeedURLColumn")
}


/// Manages the "Preferences" window.
class PreferencesController: NSWindowController {
  @IBOutlet private weak var feedsTableView: NSTableView!
  @IBOutlet private weak var removeFeedButton: NSButton!
  @IBOutlet private weak var torrentsSavePathWarningImageView: NSImageView!
  @IBOutlet private weak var automaticallyCheckForUpdatesCheckbox: NSButton!
  @IBOutlet private weak var addFeedSheetController: AddFeedController!
  @IBOutlet private weak var downloadScriptCheckbox: NSButton!
  
  // Remember if awakeFromNib has been called
  private var awake: Bool = false
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    // See RecentsController.swift
    guard !awake else { return }
    awake = true
    
    // Bind automatically check for updates checkbox to sparkle
    #if !DEBUG
    automaticallyCheckForUpdatesCheckbox.bind(
      .checkboxValue,
      to: SUUpdater.shared()!,
      withKeyPath: "automaticallyChecksForUpdates"
    )
    #endif
    
    showFeeds(self)
    
    // If the configuration isn't valid, pop up immediately
    if !Defaults.shared.isConfigurationValid { showWindow(self) }
    
    // Update UI whenever relevant defaults change
    NotificationCenter.default.addObserver(
      forName: Defaults.changedNotification,
      object: Defaults.shared,
      queue: nil,
      using: { [weak self] notification in
        self?.refresh()
      }
    )
    
    refresh()
  }
  
  private func refresh() {
    torrentsSavePathWarningImageView.image = Defaults.shared.isTorrentsSavePathValid ? #imageLiteral(resourceName: "success") : #imageLiteral(resourceName: "warning")
    feedsTableView.reloadData()
    
    refreshRemoveButton()
  }
  
  private func refreshRemoveButton() {
    removeFeedButton.isEnabled = !feedsTableView.selectedRowIndexes.isEmpty
  }
  
  deinit {
    automaticallyCheckForUpdatesCheckbox.unbind(.checkboxValue)
    NotificationCenter.default.removeObserver(self)
  }
}


// MARK: Actions
extension PreferencesController {
  @IBAction override func showWindow(_ sender: Any?) {
    NSApp.activate(ignoringOtherApps: true)
    super.showWindow(sender)
  }
  
  @IBAction private func addFeed(_: Any?) {
    window?.beginSheet(addFeedSheetController.window!, completionHandler: nil)
  }
  
  @IBAction private func removeSelectedFeeds(_: Any?) {
    for feedIndex in feedsTableView.selectedRowIndexes.reversed() {
      Defaults.shared.feeds.remove(at: feedIndex)
    }
  }
  
  @IBAction private func importFromOPMLFile(_: Any?) {
    guard let window = self.window else { return }
    
    let openPanel = NSOpenPanel()
    openPanel.allowsMultipleSelection = false
    openPanel.canChooseDirectories = false
    openPanel.canChooseFiles = true
    
    openPanel.beginSheetModal(for: window) { response in
      guard response == .OK, let url = openPanel.url else { return }
      
      do {
        let data = try Data(contentsOf: url)
        let parsedFeeds = try OPMLParser.parse(opml: data)
        Defaults.shared.feeds += parsedFeeds
      } catch {
        NSLog("Couldn't parse OPML: \(error)")
      }
    }
  }
  
  @IBAction private func savePreferences(_: Any?) {
    Defaults.shared.save()
    
    guard Defaults.shared.isConfigurationValid else {
      // Show the Feeds tab because all possible invalid inputs are currently there
      showFeeds(self)
      
      // Shake the window to signal invalid input
      window?.performShakeAnimation(duration: 0.3)
      
      return
    }
    
    // Hide the Preferences window
    window?.close()
    
    // Also force check
    FeedChecker.shared.forceCheck()
  }
  
  @IBAction fileprivate func showFeeds(_: Any?) {
    // Select the Feeds tab
    window?.toolbar?.selectedItemIdentifier = .init(rawValue: "Feed")
  }
  
  @IBAction fileprivate func showDownloads(_: Any?) {
    // Select the Downloads tab
    window?.toolbar?.selectedItemIdentifier = .init(rawValue: "Downloads")
  }
  
  @IBAction private func showTweaks(_: Any?) {
    // Select the Tweaks tab
    window?.toolbar?.selectedItemIdentifier = .init(rawValue: "Tweaks")
  }
}


extension PreferencesController: NSTableViewDataSource {
  func numberOfRows(in tableView: NSTableView) -> Int {
    return Defaults.shared.feeds.count
  }
}


extension PreferencesController: NSTableViewDelegate {
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    // Get the item to display
    let feed = Defaults.shared.feeds[row]
    
    if tableColumn?.identifier == .feedNameColumn {
      guard let cell = tableView.makeView(withIdentifier: .feedNameColumn, owner: self) as? NSTableCellView else {
        return nil
      }
      cell.textField?.stringValue = feed.name
      return cell
    } else if tableColumn?.identifier == .feedURLColumn {
      guard let cell = tableView.makeView(withIdentifier: .feedURLColumn, owner: self) as? NSTableCellView else {
        return nil
      }
      cell.textField?.stringValue = feed.url.absoluteString
      return cell
    } else {
      return nil
    }
  }
  
  func tableViewSelectionDidChange(_ notification: Notification) {
    refreshRemoveButton()
  }
}
