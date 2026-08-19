import Flutter
import UIKit

public class SwiftFlutterProgressDialogPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_progress_dialog", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterProgressDialogPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
