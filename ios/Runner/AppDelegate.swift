import UIKit
import Flutter
import Firebase
import WatchConnectivity

@available(iOS 9.3, *)

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, WCSessionDelegate {
        
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: "watchAppActivated",
                binaryMessenger: controller.binaryMessenger)
        channel.invokeMethod("watchActivated",arguments: nil)
    }
        
    func sessionDidBecomeInactive(_ session: WCSession) {
    
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
        
    func sendString(text: String){
        let session = WCSession.default;
        if(session.isPaired && session.isReachable){
            DispatchQueue.main.async {
                session.sendMessage(["qr_text": text], replyHandler: nil)
            }
        }else{
            print("Watch not reachable...")
        }
    }
    
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    //watchOS Support
    // You start you session with the watch by calling .activate() in your session.
    if(WCSession.isSupported()){
                  let session = WCSession.default;
                  session.delegate = self;
                  session.activate();
    }
    
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "watchQRValue",
              binaryMessenger: controller.binaryMessenger)

    channel.setMethodCallHandler({
        (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
       if(call.method == "sendStringToNative"){
       // We will call a method called "sendStringToNative" in flutter.
          self.sendString(text: call.arguments as! String)
          }
    })
    
    let appCtrlChannel = FlutterMethodChannel(name: "appControl",
              binaryMessenger: controller.binaryMessenger)

    //TODO: WARNING This might not pass App Store Review
    appCtrlChannel.setMethodCallHandler({
        (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
       /*if(call.method == "exit"){
        UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
                Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { (timer) in
                    exit(0)
                }
       }
       else if(call.method == "minimize"){
         UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
        }*/
       })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  //quick_actions item click not work, should copy this method to AppDelegate.swift'
  // @see Issue (https://github.com/flutter/flutter/issues/46155)
      override func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
      let controller = window.rootViewController as? FlutterViewController

      let channel = FlutterMethodChannel(name: "plugins.flutter.io/quick_actions", binaryMessenger: controller! as! FlutterBinaryMessenger)
      channel.invokeMethod("launch", arguments: shortcutItem.type)
      }
}
