import Foundation


extension NSUserNotificationCenter {
  func deliverNewEpisodeNotification(for episode: Episode) {
    let notification = NSUserNotification()
    notification.title = NSLocalizedString("newtorrent", comment: "New torrent notification")
    notification.informativeText = .localizedStringWithFormat(
      NSLocalizedString("newtorrentdesc", comment: "New torrent notification"),
      episode.title
    )
    notification.soundName = NSUserNotificationDefaultSoundName
    deliver(notification)
  }
}
