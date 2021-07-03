//
//  WatchConnectivity.swift
//  nano Extension
//
//  Created by Kavin Zhao on 2021/7/3.
//

import Foundation
import WatchConnectivity
import SwiftUI

class wcDelegate: NSObject, WCSessionDelegate, ObservableObject {
    let session = WCSession.default;
    @Published var token = ""
    
    override init() {
        super.init()
        token = getFduholeToken()
        session.delegate = self
        session.activate()
    }
    
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func sendString(text: String) -> Bool  {
        if(session.isReachable){
            DispatchQueue.main.async {
                self.session.sendMessage(["fduhole": text], replyHandler: nil, errorHandler: {error -> Void in
                    print(error)
                })
            }
            return true
        }
        return false
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.token = message["fduhole_token"] as! String
        }
        setFduholeToken(token: message["fduhole_token"] as! String)
    }
    
    let defaults = UserDefaults.standard
    func setFduholeToken(token: String) -> Void {
        defaults.set(token, forKey: "fduhole_token")
    }
    
    func getFduholeToken() -> String {
        return defaults.string(forKey: "fduhole_token") ?? ""
    }
}
