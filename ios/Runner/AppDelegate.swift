import UIKit
import Flutter
import Firebase
import WatchConnectivity

@available(iOS 9.3, *)

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, WCSessionDelegate {
    let defaults = UserDefaults.standard
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        /*if (defaults.bool(forKey: "token_set")) {
            let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
            let channel = FlutterMethodChannel(name: "fduhole",
                                               binaryMessenger: controller.binaryMessenger)
            channel.invokeMethod("get_token", arguments: nil)
        }*/
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        if (userInfo["token_set"] != nil) {
            defaults.set(true, forKey: "token_set")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: "fduhole",
                                           binaryMessenger: controller.binaryMessenger)
        channel.invokeMethod("get_token", arguments: nil)
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
    }
    
    func sendString(text: String) {
        let session = WCSession.default;
        if(WCSession.isSupported()){
            DispatchQueue.main.async {
                session.sendMessage(["token": text], replyHandler: nil)
            }
        }
    }
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        FirebaseApp.configure()
        
        //watchOS Support
        if(WCSession.isSupported()){
            let session = WCSession.default;
            session.delegate = self;
            session.activate();
        }
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: "fduhole",
                                           binaryMessenger: controller.binaryMessenger)
        channel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            if(call.method == "send_token"){
                // We will call a method called "sendStringToNative" in flutter.
                self.sendString(text: call.arguments as! String)
            }
        })
        
        /*let appCtrlChannel = FlutterMethodChannel(name: "appControl",
         binaryMessenger: controller.binaryMessenger)
         
         //TODO: WARNING This might not pass App Store Review
         appCtrlChannel.setMethodCallHandler({
         (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
         if(call.method == "exit"){
         UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
         Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { (timer) in
         exit(0)
         }
         }
         else if(call.method == "minimize"){
         UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
         }
         })*/
        
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
