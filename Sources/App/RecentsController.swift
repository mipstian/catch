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
    NSApp.activate(ignoringOtherApps: true)
    super.showWindow(sender)
  }
  
  @IBAction private func downloadRecentItemAgain(_ senderButton: NSButton) {
    let clickedRow = table.row(for: senderButton)
    let recentEpisode = Defaults.shared.downloadHistory[clickedRow].episode
    if recentEpisode.isMagnetized {
      if Defaults.shared.runScript {
        executeScript(recentEpisode.url.absoluteString)
      } else {
        Browser.openInBackground(url: recentEpisode.url)
      }
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
              if Defaults.shared.runScript {
                self.executeScript(downloadedEpisode.localURL!.path)
              } else {
                Browser.openInBackground(file: downloadedEpisode.localURL!.path)
              }
            }
          case .failure(let error):
            NSLog("Feed Helper error (downloading file): \(error)")
          }
        }
      )
    }
  }
  
  private func executeScript(_ argument : String!) {
    if Defaults.shared.runScript {
      let task = Process()
      let pipe = Pipe()
      task.launchPath = Defaults.shared.scriptPath?.path
      task.standardOutput = pipe
      task.arguments = [argument]
      task.launch()
      let handle = pipe.fileHandleForReading
      let data = handle.readDataToEndOfFile()
      let printing = String (data: data, encoding: String.Encoding.utf8)
      NSLog("%@", printing!)
    }
  }
}
