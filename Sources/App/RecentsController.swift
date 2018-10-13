import AppKit


private extension NSUserInterfaceItemIdentifier {
  static let recentsCell = NSUserInterfaceItemIdentifier(rawValue: "RecentCell")
}


/// Manages the "Recent Episodes" window.
class RecentsController: NSWindowController {
  @IBOutlet private weak var table: NSTableView!
  
  private let downloadDateFormatter = DateFormatter()
  private let feedHelperProxy = FeedHelperProxy()
  
  private var sortedHistory: [HistoryItem] = []
  
  private var feedCheckerObserver: NSObjectProtocol? = nil
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    // Configure formatter for torrent download dates
    downloadDateFormatter.timeStyle = .short
    downloadDateFormatter.dateStyle = .short
    downloadDateFormatter.doesRelativeDateFormatting = true
    
    // Unsubscribe from everything first, so we don't subscribe multiple times.
    // Why would this run multiple times you ask?
    // Because (from the docs of NSTableView.makeView(withIdentifier:owner:)):
    //
    // Note that awakeFromNib() is called each time this method is called,
    // which means that awakeFromNib is also called on owner, even though the
    // owner is already awake.
    //
    // Makes no sense to me but whatever :)
    unsubscribeFromEverything()
    
    // Subscribe to history changes
    feedCheckerObserver = NotificationCenter.default.addObserver(
      forName: FeedChecker.stateChangedNotification,
      object: FeedChecker.shared,
      queue: nil,
      using: { [weak self] _ in
        self?.reloadHistory()
      }
    )
  }
  
  private func reloadHistory() {
    // Keep a sorted copy of the download history, in reverse cronological order
    sortedHistory = Defaults.shared.downloadHistory.sorted().reversed()
    table.reloadData()
  }
  
  private func unsubscribeFromEverything() {
    if let feedCheckerObserver = feedCheckerObserver {
      NotificationCenter.default.removeObserver(feedCheckerObserver)
    }
  }
  
  deinit {
    unsubscribeFromEverything()
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
    
    cell.downloadDateTextField.stringValue = historyItem.downloadDate.map(downloadDateFormatter.string) ?? ""
    
    return cell
  }
  
  func selectionShouldChange(in tableView: NSTableView) -> Bool {
    return false
  }
}


// MARK: Actions
extension RecentsController {
  @IBAction override func showWindow(_ sender: Any?) {
    reloadHistory()
    NSApp.activate(ignoringOtherApps: true)
    super.showWindow(sender)
  }
  
  @IBAction private func downloadRecentItemAgain(_ senderButton: NSButton) {
    let clickedRow = table.row(for: senderButton)
    let recentEpisode = Defaults.shared.downloadHistory[clickedRow].episode
    if recentEpisode.isMagnetized {
      Browser.openInBackground(url: recentEpisode.url)
    } else {
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
              Browser.openInBackground(file: downloadedEpisode.localURL!.path)
            }
          case .failure(let error):
            NSLog("Feed Helper error (downloading file): \(error)")
          }
        }
      )
    }
  }
}
