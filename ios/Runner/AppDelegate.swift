import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  //quick_actions item click not work, should copy this method to AppDelegate.swift'
  // @see Issue (https://github.com/flutter/flutter/issues/46155)
      @available(iOS 9.0, *)
      override func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
      let controller = window.rootViewController as? FlutterViewController

      let channel = FlutterMethodChannel(name: "plugins.flutter.io/quick_actions", binaryMessenger: controller! as! FlutterBinaryMessenger)
      channel.invokeMethod("launch", arguments: shortcutItem.type)
      }
}
