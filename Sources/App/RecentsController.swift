import AppKit


class RecentsController: NSWindowController {
  @IBOutlet fileprivate weak var table: NSTableView!
  
  fileprivate let downloadDateFormatter = DateFormatter()
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    // Configure formatter for torrent download dates
    downloadDateFormatter.timeStyle = .short
    downloadDateFormatter.dateStyle = .short
    downloadDateFormatter.doesRelativeDateFormatting = true
    
    // Subscribe to history changes
    NotificationCenter.default.addObserver(
      forName: FeedChecker.statusChangedNotification,
      object: FeedChecker.shared,
      queue: nil,
      using: { [weak self] _ in
        self?.table.reloadData()
      }
    )
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}


extension RecentsController: NSTableViewDataSource {
  func numberOfRows(in tableView: NSTableView) -> Int {
    return Defaults.shared.downloadHistory.count
  }
}


extension RecentsController: NSTableViewDelegate {
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    let historyItem = Defaults.shared.downloadHistory[row]
    
    guard let cell = tableView.make(withIdentifier: "RecentCell", owner: self) as? RecentsCellView else {
      return nil
    }
    
    cell.textField?.stringValue = historyItem.title
    
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
    table.reloadData()
    NSApp.activate(ignoringOtherApps: true)
    super.showWindow(sender)
  }
  
  @IBAction private func downloadRecentItemAgain(_ senderButton: NSButton) {
    let clickedRow = table.row(for: senderButton)
    let recentToDownload = Defaults.shared.downloadHistory[clickedRow]
    let isMagnetLink = recentToDownload.isMagnetLink
    if isMagnetLink {
      Browser.openInBackground(url: recentToDownload.url)
    } else {
      FeedChecker.shared.downloadHistoryItem(recentToDownload) { downloadedFile, error in
        guard Defaults.shared.shouldOpenTorrentsAutomatically, let downloadedFile = downloadedFile else {
          return
        }
        Browser.openInBackground(file: downloadedFile["torrentFilePath"] as! String)
      }
    }
  }
}
