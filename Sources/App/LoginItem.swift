import Foundation


extension Bundle {
  private static var loginItemsList: LSSharedFileList? {
    return LSSharedFileListCreate(
      nil,
      kLSSharedFileListSessionLoginItems.takeRetainedValue(),
      nil
    )?.takeRetainedValue()
  }
  
  private var loginItem: LSSharedFileListItem? {
    guard
      let list = Bundle.loginItemsList,
      let loginItems = LSSharedFileListCopySnapshot(list, nil).takeRetainedValue() as? [LSSharedFileListItem]
    else {
        return nil
    }
    
    return loginItems.first { item in
      guard let itemUrlRef = LSSharedFileListItemCopyResolvedURL(item, 0, nil) else { return false }
      
      let itemUrl = itemUrlRef.takeRetainedValue() as URL
      return itemUrl == bundleURL
    }
  }
  
  var isLoginItem: Bool {
    get {
      return loginItem != nil
    }
    set {
      let shouldRegister = newValue
      
      NSLog(shouldRegister ? "Adding app to login items" : "Removing app from login items")
      
      guard let loginItemsList = Bundle.loginItemsList else {
        NSLog("Couldn't get login items list")
        return
      }
      
      if shouldRegister {
        LSSharedFileListInsertItemURL(
          loginItemsList,
          nil,
          nil,
          nil,
          bundleURL as CFURL,
          nil,
          nil
        )
      } else {
        if let loginItem = loginItem {
          LSSharedFileListItemRemove(loginItemsList, loginItem)
        }
      }
    }
  }
}
