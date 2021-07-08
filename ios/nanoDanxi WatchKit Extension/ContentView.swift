//
//  ContentView.swift
//  nanoDanxi WatchKit Extension
//
//  Created by Kavin Zhao on 2021/7/3.
//

import SwiftUI
import WatchKit

struct ContentView: View {
    @EnvironmentObject var fduholeLoginInfo: WatchSessionDelegate
    @State private var connectionReachable = true;
    
    
    var body: some View {
        if (fduholeLoginInfo.token == "") {
            VStack {
                if (connectionReachable) {
                    ProgressView()
                    Text("gettingtoken")
                }
                else {
                    Text("iphoneunreachable")
                }
                /*TextField("test", text: $capturedText)
                { isEditing in
                    
                } onCommit: {
                    UserDefaults.standard.set(capturedText, forKey: "fduhole_token")
                    fduholeLoginInfo.token = capturedText
                }
                .textContentType(.oneTimeCode)*/
            }
            .onAppear() {
                WatchSessionDelegate.shared.activate()
                connectionReachable = WatchSessionDelegate.shared.requestToken()
            }
            .onTapGesture() {
                connectionReachable = WatchSessionDelegate.shared.requestToken()
            }
        }
        else {
            TreeHolePage()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
