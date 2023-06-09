import Foundation


let serviceListener = NSXPCListener.service()
serviceListener.delegate = Service.shared
serviceListener.resume()
