import AppKit


/// Manages the "Feed Contents" window.
class FeedContentsController: NSWindowController {
  @IBOutlet private var textView: NSTextView!
  @IBOutlet private var progressIndicator: NSProgressIndicator!
  
  private let feedHelperProxy = FeedHelperProxy()
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    if #available(OSX 10.15, *) {
      textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
    }
  }
  
  func loadFeed(_ feed: Feed) {
    textView.string = ""
    textView.isSelectable = false
    progressIndicator.startAnimation(self)
    
    feedHelperProxy.download(feed: feed) { [weak self] result in
      self?.progressIndicator.stopAnimation(self)
      
      switch result {
      case .success(let feedContents):
        if let string = String(data: feedContents, encoding: .utf8) {
          self?.textView.string = string
          self?.textView.isSelectable = true
        }
      case .failure(let error):
        NSLog("Feed Helper error (downloading feed contents): \(error)")
      }
    }
  }
}
