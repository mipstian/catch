import AppKit


extension NSWindow {
  // Stolen from: http://stackoverflow.com/questions/10517386
  func performShakeAnimation() {
    let numberOfShakes = 2
    let shakeDuration: TimeInterval = 0.3
    let shakeIntensity: CGFloat = 0.015
    
    let shakeAnimation = CAKeyframeAnimation()
    
    let xOffset = frame.width * shakeIntensity
    
    let shakePath = CGMutablePath()
    shakePath.move(to: CGPoint(x: frame.minX, y: frame.minY))
    for _ in 0..<numberOfShakes {
      shakePath.addLine(to: CGPoint(x: frame.minX - xOffset, y: frame.minY))
      shakePath.addLine(to: CGPoint(x: frame.minX + xOffset, y: frame.minY))
    }
    shakePath.closeSubpath()
    
    shakeAnimation.path = shakePath
    shakeAnimation.duration = shakeDuration
    
    animations = ["frameOrigin": shakeAnimation]
    animator().setFrameOrigin(frame.origin)
  }
}
