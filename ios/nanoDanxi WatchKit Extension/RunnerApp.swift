//
//  RunnerApp.swift
//  nanoDanxi WatchKit Extension
//
//  Created by Kavin Zhao on 2021/7/3.
//

import SwiftUI

@main
struct RunnerApp: App {
    @StateObject var fduholeLoginInfo = WatchSessionDelegate.shared
    
    init() {
        if (UserDefaults.standard.string(forKey: KEY_FDUHOLE_TOKEN) == nil) {
            WatchSessionDelegate.shared.activate()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
            .environmentObject(fduholeLoginInfo)
        }
    }
}
