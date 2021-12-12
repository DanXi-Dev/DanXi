//
//  WatchConnectivity.swift
//  nano Extension
//
//  Created by Kavin Zhao on 2021/7/3.
//

import Foundation
import WatchConnectivity
import SwiftUI

let KEY_FDUHOLE_TOKEN = "fduhole_token_v2"

class WatchSessionDelegate: NSObject, WCSessionDelegate, ObservableObject {
    let session = WCSession.default;
    static var shared = WatchSessionDelegate()
    
    @Published var token = ""
    
    func activate() {
        session.delegate = self
        session.activate()
    }
    
    func initialize() {
        token = getFduholeToken()
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
    func requestToken() -> Bool {
        if(!session.isReachable) {
            return false
        }
        DispatchQueue.main.async {
            self.session.sendMessage(["requestToken": true], replyHandler: nil)
        }
        return true
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.token = message["token"] as! String
        }
        setFduholeToken(token: message["token"] as! String)
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        DispatchQueue.main.async {
            self.token = userInfo["token"] as! String
        }
        self.setFduholeToken(token: userInfo["token"] as! String)
        session.transferUserInfo(["token_set": true])
    }
    
    let defaults = UserDefaults.standard
    func setFduholeToken(token: String) -> Void {
        defaults.set(token, forKey: KEY_FDUHOLE_TOKEN)
    }
    
    func getFduholeToken() -> String {
        return defaults.string(forKey: KEY_FDUHOLE_TOKEN) ?? ""
    }
}
