import AppKit


/// Manages the "Feed Contents" window.
class FeedContentsController: NSWindowController {
  @IBOutlet private var textView: NSTextView!
  @IBOutlet private var progressIndicator: NSProgressIndicator!
  
  private let feedHelperProxy = FeedHelperProxy()
  private var loadingFeedsCount = 0 { didSet { refresh() } }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    if #available(OSX 10.15, *) {
      textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
    }
  }
  
  func refresh() {
    if loadingFeedsCount == 0 {
      textView.alphaValue = 1
      textView.isSelectable = true
      progressIndicator.stopAnimation(self)
    } else {
      textView.alphaValue = 0.5
      textView.isSelectable = false
      progressIndicator.startAnimation(self)
    }
  }
  
  func loadFeed(_ feed: Feed) {
    loadingFeedsCount += 1
    
    feedHelperProxy.download(feed: feed) { [weak self] result in
      switch result {
      case .success(let feedContents):
        if let string = String(data: feedContents, encoding: .utf8) {
          self?.textView.string = string
        }
      case .failure(let error):
        NSLog("Feed Helper error (downloading feed contents): \(error)")
      }
      
      self?.loadingFeedsCount -= 1
    }
  }
}
