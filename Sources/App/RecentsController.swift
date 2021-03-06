import AppKit
import os


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
    
    window?.title = NSLocalizedString("Recent Episodes", comment: "")
    
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
      title: NSLocalizedString("Copy Link", comment: ""),
      action: #selector(copyURL),
      keyEquivalent: ""
    )
    copyURLItem.target = self
    contextMenu.addItem(copyURLItem)
    
    let deleteItem = NSMenuItem(
      title: NSLocalizedString("Delete", comment: ""),
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
    sortedHistory = Defaults.shared.downloadHistory
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
    
    if Defaults.shared.isDownloadScriptEnabled {
      Process.runDownloadScript(url: recentEpisode.url)
    } else {
      if recentEpisode.url.isMagnetLink {
        NSWorkspace.shared.openInBackground(url: recentEpisode.url)
      } else {
        guard Defaults.shared.isConfigurationValid, let downloadOptions = Defaults.shared.downloadOptions else {
          os_log("Cannot download torrent file with invalid preferences", log: .main, type: .info)
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
              os_log("Feed Helper error (downloading file): %{public}@", log: .main, type: .error, error.localizedDescription)
            }
          }
        )
      }
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
    }
    NSPasteboard.general.setString(recentEpisode.url.absoluteString, forType: .string)
  }
  
  @IBAction func deleteHistoryItem(_ sender: Any?) {
    guard let clickedHistoryItem = clickedHistoryItem() else { return }
    
    Defaults.shared.downloadHistory.removeAll { $0 == clickedHistoryItem }
  }
}
