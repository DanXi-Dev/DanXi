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
        // Read FDUHOLE Token
        WatchSessionDelegate.shared.initialize()
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
