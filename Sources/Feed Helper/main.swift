import Foundation


let serviceListener = NSXPCListener.service()
let feedHelper = FeedHelper.shared
serviceListener.delegate = feedHelper
serviceListener.resume()
