import Foundation
import os


extension OSLog {
  private static var subsystem = "com.giorgiocalderolla.Catch"
  
  static let main = OSLog(subsystem: subsystem, category: "main")
  static let helper = OSLog(subsystem: subsystem, category: "helper")
}
