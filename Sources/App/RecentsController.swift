import AppKit


private extension NSUserInterfaceItemIdentifier {
  static let recentsCell = NSUserInterfaceItemIdentifier(rawValue: "RecentCell")
}


/// Manages the "Recent Episodes" window.
class RecentsController: NSWindowController {
  @IBOutlet private weak var table: NSTableView!
  
  private let contextMenu = NSMenu(title: "")
  
  private let downloadDateFormatter = DateFormatter()
  private let feedHelperProxy = FeedHelperProxy()
  
  private var sortedHistory: [HistoryItem] = []
  
  private var downloadHistoryObserver: NSObjectProtocol? = nil
  
  // Remember if awakeFromNib has been called
  private var awake: Bool = false
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    // Make sure the following only runs once per instance.
    // Why would this run multiple times you ask?
    // Because (from the docs of NSTableView.makeView(withIdentifier:owner:)):
    //
    // Note that awakeFromNib() is called each time this method is called,
    // which means that awakeFromNib is also called on owner, even though the
    // owner is already awake.
    //
    // Makes no sense to me but whatever :)
    guard !awake else { return }
    awake = true
    
    // Configure formatter for torrent download dates
    downloadDateFormatter.timeStyle = .short
    downloadDateFormatter.dateStyle = .short
    downloadDateFormatter.doesRelativeDateFormatting = true
    
    // Subscribe to changes to the download history
    downloadHistoryObserver = NotificationCenter.default.addObserver(
      forName: Defaults.downloadHistoryChangedNotification,
      object: Defaults.shared,
      queue: nil,
      using: { [weak self] _ in
        self?.reloadHistory()
      }
    )
    
    let copyURLItem = NSMenuItem(
      title: "Copy Link",
      action: #selector(copyURL),
      keyEquivalent: ""
    )
    copyURLItem.target = self
    contextMenu.addItem(copyURLItem)
    
    let deleteItem = NSMenuItem(
      title: "Delete",
      action: #selector(deleteHistoryItem),
      keyEquivalent: ""
    )
    deleteItem.target = self
    contextMenu.addItem(deleteItem)
    
    table.menu = contextMenu
    
    reloadHistory()
  }
  
  private func reloadHistory() {
    // Keep a sorted copy of the download history, in reverse cronological order
    sortedHistory = Defaults.shared.downloadHistory.sorted().reversed()
    table.reloadData()
  }
  
  deinit {
    if let observer = downloadHistoryObserver {
      NotificationCenter.default.removeObserver(observer)
    }
  }
}


extension RecentsController: NSTableViewDataSource {
  func numberOfRows(in tableView: NSTableView) -> Int {
    return sortedHistory.count
  }
}


extension RecentsController: NSTableViewDelegate {
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    // Get the item to display
    let historyItem = sortedHistory[row]
    
    guard let cell = tableView.makeView(withIdentifier: .recentsCell, owner: self) as? RecentsCellView else {
      return nil
    }
    
    cell.textField?.stringValue = historyItem.episode.title
    
    let formattedDownloadDate = historyItem.downloadDate.map(downloadDateFormatter.string)
    
    let feedName = historyItem.episode.feed?.name ?? "ShowRSS"
    
    let subtitle: String
    if let formattedDownloadDate = formattedDownloadDate {
      subtitle = "\(feedName) • \(formattedDownloadDate)"
    } else {
      subtitle = feedName
    }
    
    cell.downloadDateTextField.stringValue = subtitle
    
    let canDownloadNonTorrents = Defaults.shared.downloadScriptEnabled && Defaults.shared.downloadScriptPath != nil
    let isTorrent = historyItem.episode.url.isMagnetLink || historyItem.episode.url.absoluteString.isTorrentFilePath
    let canDownloadAgain = isTorrent || canDownloadNonTorrents
    cell.downloadAgainButton.isHidden = !canDownloadAgain
    
    return cell
  }
  
  func selectionShouldChange(in tableView: NSTableView) -> Bool {
    return false
  }
}


// MARK: Actions
extension RecentsController {
  @IBAction override func showWindow(_ sender: Any?) {
    NSApp.activate(ignoringOtherApps: true)
    super.showWindow(sender)
  }
  
  @IBAction private func downloadRecentItemAgain(_ senderButton: NSButton) {
    let clickedRow = table.row(for: senderButton)
    let recentEpisode = Defaults.shared.downloadHistory[clickedRow].episode
    if recentEpisode.url.isMagnetLink {
      NSWorkspace.shared.openInBackground(url: recentEpisode.url)
    } else if recentEpisode.url.absoluteString.isTorrentFilePath {
      guard Defaults.shared.isConfigurationValid, let downloadOptions = Defaults.shared.downloadOptions else {
        NSLog("Cannot download torrent file with invalid preferences")
        return
      }
      
      feedHelperProxy.download(
        episode: recentEpisode,
        downloadOptions: downloadOptions,
        completion: { result in
          switch result {
          case .success(let downloadedEpisode):
            if Defaults.shared.shouldOpenTorrentsAutomatically {
              NSWorkspace.shared.openInBackground(file: downloadedEpisode.localURL!.path)
            }
          case .failure(let error):
            NSLog("Feed Helper error (downloading file): \(error)")
          }
        }
      )
    } else {
      Process.runDownloadScript(url: recentEpisode.url)
    }
  }
  
  private func clickedHistoryItem() -> HistoryItem? {
    let clickedRow = table.clickedRow
    guard clickedRow != -1 else { return nil }
    return sortedHistory[clickedRow]
  }
  
  @IBAction func copyURL(_ sender: Any?) {
    guard let clickedHistoryItem = clickedHistoryItem() else { return }
    
    let recentEpisode = clickedHistoryItem.episode
    NSPasteboard.general.clearContents()
    if #available(OSX 10.13, *) {
      NSPasteboard.general.setString(recentEpisode.url.absoluteString, forType: .URL)
    } else {
      NSPasteboard.general.setString(recentEpisode.url.absoluteString, forType: .string)
    }
  }
  
  @IBAction func deleteHistoryItem(_ sender: Any?) {
    guard let clickedHistoryItem = clickedHistoryItem() else { return }
    
    Defaults.shared.downloadHistory.removeAll { $0 == clickedHistoryItem }
  }
}
