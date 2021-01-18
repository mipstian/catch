import Foundation


/// A TV show episode, as found in broadcatching feeds
struct Episode: Equatable, Hashable {
  /// Title of the episode
  ///
  /// - Note: in feeds, this usually contains a season/episode number code and
  ///         other stuff that isn't strictly the title
  var title: String
  
  /// Magnet link, .torrent file, or generic URL for this episode
  var url: URL
  
  /// Name of the TV show this episode is from, if available.
  var showName: String?
  
  /// The feed this episode was downloaded from, if known.
  var feed: Feed?
}


struct DownloadedEpisode {
  var episode: Episode
  
  /// Where the .torrent file was saved to the file system, if it was
  var localURL: URL?
}


// MARK: Serialization
extension Episode {
  var dictionaryRepresentation: [AnyHashable:Any] {
    var dictionary: [AnyHashable:Any] = [
      "title": title,
      "url": url.absoluteString
    ]
    if let showName = showName {
      dictionary["showName"] = showName
    }
    if let feed = feed {
      dictionary["feed"] = feed.dictionaryRepresentation
    }
    return dictionary
  }
}


extension DownloadedEpisode {
  var dictionaryRepresentation: [AnyHashable:Any] {
    var dictionary = episode.dictionaryRepresentation
    if let localURL = localURL {
      dictionary["localURL"] = localURL.absoluteString
    }
    return dictionary
  }
}


// MARK: Deserialization
extension Episode {
  init?(dictionary: [AnyHashable:Any]) {
    guard
      let title = dictionary["title"] as? String,
      let url = (dictionary["url"] as? String).flatMap(URL.init(string:))
    else {
      return nil
    }
    
    self.title = title
    self.url = url
    self.showName = dictionary["showName"] as? String
    
    if
      let feedDictionary = dictionary["feed"] as? [AnyHashable:Any],
      let feed = Feed(dictionary: feedDictionary) {
      self.feed = feed
    } else {
      self.feed = nil
    }
  }
}


extension DownloadedEpisode {
  init?(dictionary: [AnyHashable:Any]) {
    guard let episode = Episode(dictionary: dictionary) else { return nil }
    
    self.episode = episode
    self.localURL = (dictionary["localURL"] as? String).flatMap(URL.init(string:))
  }
}
