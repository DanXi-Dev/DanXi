import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    
    // Set Window Initial Size
    // TODO: This code should be remove when flutter framework supports it natively
    // original code: self.setFrame(windowFrame, display: true)
    self.setFrame(NSRect(x: windowFrame.minX, y: windowFrame.minY, width: 400, height: 700), display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
