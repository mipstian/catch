import Foundation


// Standard XPC service setup
let serviceListener = NSXPCListener.service()
serviceListener.delegate = Service.shared
serviceListener.resume()
