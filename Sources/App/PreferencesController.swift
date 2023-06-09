import AppKit
import Sparkle


private extension NSUserInterfaceItemIdentifier {
  static let feedCell = NSUserInterfaceItemIdentifier(rawValue: "FeedCell")
}


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
  
  @IBOutlet private var feedContentsController: FeedContentsController!
  
  private let feedsTableContextMenu = NSMenu(title: "")
  
  private var sortedFeedList: [Feed] = []
  
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
    
    // Set up context menu actions
    do {
      let copyNameItem = NSMenuItem(
        title: NSLocalizedString("Copy Name", comment: ""),
        action: #selector(copyName),
        keyEquivalent: ""
      )
      copyNameItem.target = self
      feedsTableContextMenu.addItem(copyNameItem)
      
      let copyAddressItem = NSMenuItem(
        title: NSLocalizedString("Copy Address", comment: ""),
        action: #selector(copyAddress),
        keyEquivalent: ""
      )
      copyAddressItem.target = self
      feedsTableContextMenu.addItem(copyAddressItem)
      
      let showContentsItem = NSMenuItem(
        title: NSLocalizedString("Show Contents", comment: ""),
        action: #selector(showContents),
        keyEquivalent: ""
      )
      showContentsItem.target = self
      feedsTableContextMenu.addItem(showContentsItem)
      
      feedsTableView.menu = feedsTableContextMenu
    }
    
    refresh()
  }
  
  private func refresh() {
    if #available(OSX 11.0, *) {
      let image = Defaults.shared.isTorrentsSavePathValid ?
        NSImage(
          systemSymbolName: "checkmark.circle.fill",
          accessibilityDescription: nil
        ) :
        NSImage(
          systemSymbolName: "questionmark.folder.fill",
          accessibilityDescription: nil
        )
      torrentsSavePathWarningImageView.image = image?
        .withSymbolConfiguration(.init(scale: .large))
      torrentsSavePathWarningImageView.contentTintColor = Defaults.shared.isTorrentsSavePathValid ?
        nil : .orange
    } else {
      torrentsSavePathWarningImageView.image = Defaults.shared.isTorrentsSavePathValid ? #imageLiteral(resourceName: "success") : #imageLiteral(resourceName: "warning")
    }
    
    reloadFeedList()
    
    refreshRemoveButton()
  }
  
  private func reloadFeedList() {
    sortedFeedList = Defaults.shared.feeds.sorted { $0.name.localizedLowercase < $1.name.localizedLowercase }
    
    feedsTableView.reloadData()
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
      let feedToRemove = sortedFeedList[feedIndex]
      Defaults.shared.feeds.removeAll { $0 == feedToRemove }
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
    window?.toolbar?.selectedItemIdentifier = .init(rawValue: "Feeds")
  }
  
  @IBAction fileprivate func showDownloads(_: Any?) {
    // Select the Downloads tab
    window?.toolbar?.selectedItemIdentifier = .init(rawValue: "Downloads")
  }
  
  @IBAction private func showTweaks(_: Any?) {
    // Select the Tweaks tab
    window?.toolbar?.selectedItemIdentifier = .init(rawValue: "Tweaks")
  }
  
  private func clickedFeed() -> Feed? {
    let clickedRow = feedsTableView.clickedRow
    guard clickedRow != -1 else { return nil }
    return sortedFeedList[clickedRow]
  }
  
  @IBAction func copyName(_ sender: Any?) {
    guard let feed = clickedFeed() else { return }
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(feed.name, forType: .string)
  }
  
  @IBAction func copyAddress(_ sender: Any?) {
    guard let feed = clickedFeed() else { return }
    NSPasteboard.general.clearContents()
    if #available(OSX 10.13, *) {
      NSPasteboard.general.setString(feed.url.absoluteString, forType: .URL)
    } else {
      NSPasteboard.general.setString(feed.url.absoluteString, forType: .string)
    }
  }
  
  @IBAction func showContents(_ sender: Any?) {
    guard let feed = clickedFeed() else { return }
    
    feedContentsController.loadFeed(feed)
    feedContentsController.showWindow(sender)
  }
}


extension PreferencesController: NSTableViewDataSource {
  func numberOfRows(in tableView: NSTableView) -> Int {
    return sortedFeedList.count
  }
}


extension PreferencesController: NSTableViewDelegate {
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    // Get the item to display
    let feed = sortedFeedList[row]
    
    guard let cell = tableView.makeView(withIdentifier: .feedCell, owner: self) as? FeedCellView else {
      return nil
    }
    
    cell.textField?.stringValue = feed.name
    cell.urlTextField.stringValue = feed.url.absoluteString
    
    return cell
  }
  
  func tableViewSelectionDidChange(_ notification: Notification) {
    refreshRemoveButton()
  }
}
