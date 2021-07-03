//
//  RunnerApp.swift
//  nanoDanxi WatchKit Extension
//
//  Created by Kavin Zhao on 2021/7/3.
//

import SwiftUI

@main
struct RunnerApp: App {
    @StateObject var fduholeLoginInfo = fduholeTokenProvider()
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
            .environmentObject(fduholeLoginInfo)
        }
    }
}


// WCSession
import WatchKit
import Foundation
import WatchConnectivity


class fduholeTokenProvider: NSObject, WCSessionDelegate, ObservableObject {
    @Published var token = ""
    var session: WCSession
    
    init(session: WCSession = .default) {
        self.session = session
        super.init()
        self.session.delegate = self
        session.activate()
        token = getFduholeToken()
    }
    
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
    func sendString(text: String){
        let session = WCSession.default;
        if(session.isReachable){
            DispatchQueue.main.async {
                session.sendMessage(["fduhole": text], replyHandler: nil)
            }
        }else{
            //label.setText(NSLocalizedString("iPhone Unreachable.", comment: "iPhone Unreachable"))
        }
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
