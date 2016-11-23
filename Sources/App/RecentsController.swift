import AppKit


/// Manages the "Recent Episodes" window.
class RecentsController: NSWindowController {
  @IBOutlet fileprivate weak var table: NSTableView!
  
  fileprivate let downloadDateFormatter = DateFormatter()
  fileprivate let feedHelperProxy = FeedHelperProxy()
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    // Configure formatter for torrent download dates
    downloadDateFormatter.timeStyle = .short
    downloadDateFormatter.dateStyle = .short
    downloadDateFormatter.doesRelativeDateFormatting = true
    
    // Subscribe to history changes
    NotificationCenter.default.addObserver(
      forName: FeedChecker.stateChangedNotification,
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
    table.reloadData()
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
          case .success(let downloadedFile):
            if Defaults.shared.shouldOpenTorrentsAutomatically {
              Browser.openInBackground(file: downloadedFile["torrentFilePath"] as! String)
            }
          case .failure(let error):
            NSLog("Feed Helper error (downloading file): \(error)")
          }
        }
      )
    }
  }
}
