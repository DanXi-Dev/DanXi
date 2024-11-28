import UIKit
import Flutter
import WatchConnectivity

@main
@objc class AppDelegate: FlutterAppDelegate, WCSessionDelegate {
    let defaults = UserDefaults.standard
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        if (userInfo["token_set"] != nil) {
            defaults.set(true, forKey: "token_set")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            let controller : FlutterViewController = self.window?.rootViewController as! FlutterViewController
            let channel = FlutterMethodChannel(name: "fduhole",
                                               binaryMessenger: controller.binaryMessenger)
            channel.invokeMethod("get_token", arguments: nil)
        }
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
    
    override func application(_ application: UIApplication,
                              didRegisterForRemoteNotificationsWithDeviceToken
                              deviceToken: Data) {
        let token: String = deviceToken.map { String(format: "%.2hhx", $0) }.joined()
        //let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "null_device_id"
        /* Send token to FDUHole */
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: "fduhole", binaryMessenger: controller.binaryMessenger)
        channel.invokeMethod("upload_apns_token", arguments: ["token": token])
    }
    
    override func applicationWillResignActive(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    
    override func application(_ application: UIApplication,
                              didFailToRegisterForRemoteNotificationsWithError
                              error: Error) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard (settings.authorizationStatus == .authorized) ||
                    (settings.authorizationStatus == .notDetermined) else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 120.0) {
                application.registerForRemoteNotifications()
            }
        }
    }
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        if #available(iOS 15.0, *) {
              let displayLink = CADisplayLink(target: self, selector: #selector(step))
              displayLink.preferredFrameRateRange = CAFrameRateRange(minimum:80, maximum:120, preferred:120)
              displayLink.add(to: .current, forMode: .default)
            }
        /* Flutter */
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: "fduhole", binaryMessenger: controller.binaryMessenger)
        channel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            switch (call.method) {
            case "request_notification_permission":
                if #available(iOS 10.0, *) {
                    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
                    UNUserNotificationCenter.current().requestAuthorization(
                        options: authOptions,
                        completionHandler: {_, _ in })
                } else {
                    let settings: UIUserNotificationSettings =
                    UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
                    application.registerUserNotificationSettings(settings)
                }
                // This gets called regardless of whether user grants permission or not.
                application.registerForRemoteNotifications()
                result(0)
            case "send_token":
                self.sendString(text: call.arguments as! String)
                result(0)
            case "get_tag_suggestions":
                if #available(iOS 14.0, *) {
                    let re = TagPredictor.shared?.suggest(call.arguments as! String)
                    result(re)
                } else {
                    result(nil)
                }
            default:
                break
            }
        })
        
        UNUserNotificationCenter.current().delegate = self
        // Clear badge on launch
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        /* watchOS Support */
        if(WCSession.isSupported()){
            let session = WCSession.default;
            session.delegate = self;
            session.activate();
        }
        
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

    @objc func step(displaylink: CADisplayLink) {
          // Will be called once a frame has been built while matching desired frame rate
        }
}

extension AppDelegate {
    
    // This function will be called when the app receive notification
    // This override is necessary to display notification while app is in foreground
    override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // show the notification alert (banner), and with sound
        completionHandler([.alert, .sound, .badge])
    }
    
    // This function will be called right after user tap on the notification
    override func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let controller = window.rootViewController as? FlutterViewController
        let channel = FlutterMethodChannel(name: "fduhole", binaryMessenger: controller! as! FlutterBinaryMessenger)
        /*let application = UIApplication.shared
         if (application.applicationState == .active) {
         print("user tapped the notification bar when the app is in foreground")
         }
         else if (application.applicationState == .inactive) {
         print("user tapped the notification bar when the app is in background")
         }*/
        channel.invokeMethod("launch_from_notification", arguments: response.notification.request.content.userInfo)
        completionHandler()
    }
}
