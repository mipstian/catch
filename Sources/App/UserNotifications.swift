import Foundation


extension NSUserNotificationCenter {
  func deliverNotification(newEpisode: Episode) {
    let notification = NSUserNotification()
    notification.title = NSLocalizedString("newtorrent", comment: "New torrent notification")
    notification.informativeText = .localizedStringWithFormat(
      NSLocalizedString("newtorrentdesc", comment: "New torrent notification"),
      newEpisode.title
    )
    notification.soundName = NSUserNotificationDefaultSoundName
    deliver(notification)
  }
}
