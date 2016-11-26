import Foundation


// Standard XPC service setup
let serviceListener = NSXPCListener.service()
let service = Service()
serviceListener.delegate = service
serviceListener.resume()
