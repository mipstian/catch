import AppKit


class Application: NSApplication {
  /// Reimplement basic cut/copy/paste/undo/select all events
  /// - See: http://stackoverflow.com/questions/970707
  override func sendEvent(_ event: NSEvent) {
    let deviceIndependentFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
    
    guard event.type == .keyDown,
      deviceIndependentFlags.contains(.command),
      let characters = event.charactersIgnoringModifiers?.lowercased()
    else {
      super.sendEvent(event)
      return
    }
    
    switch characters {
    case "x":
      if NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: self) { return }
    case "c":
      if NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: self) { return }
    case "v":
      if NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: self) { return }
    case "a":
      if NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: self) { return }
    case "z":
      if deviceIndependentFlags.contains(.shift) {
        if NSApp.sendAction(Selector(("redo:")), to: nil, from: self) { return }
      } else {
        if NSApp.sendAction(Selector(("undo:")), to: nil, from: self) { return }
      }
    default:
      break
    }
    
    super.sendEvent(event)
  }
}
