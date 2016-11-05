import Foundation


extension NSUserNotificationCenter {
  func deliverNewEpisodeNotification(episodeTitle: String) {
    let notification = NSUserNotification()
    notification.title = NSLocalizedString("newtorrent", comment: "New torrent notification")
    notification.informativeText = String(format: NSLocalizedString("newtorrentdesc", comment: "New torrent notification"), episodeTitle)
    notification.soundName = NSUserNotificationDefaultSoundName
    deliver(notification)
  }
}
