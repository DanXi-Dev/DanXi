//
//  ContentView.swift
//  nanoDanxi WatchKit Extension
//
//  Created by Kavin Zhao on 2021/7/3.
//

import SwiftUI
import WatchKit

struct ContentView: View {
    @EnvironmentObject var fduholeLoginInfo: wcDelegate
    @State var connectionReachable = true;
    @State private var capturedText = ""
    
    
    var body: some View {
        
        if (fduholeLoginInfo.token == "") {
            VStack {
                if (connectionReachable) {
                    ProgressView()
                    Text("gettingtoken")
                        .onTapGesture {
                            connectionReachable = wcDelegate().sendString(text: "get_token")
                        }
                }
                else {
                    Text("iphoneunreachable")
                        .onTapGesture {
                            connectionReachable = wcDelegate().sendString(text: "get_token")
                        }
                }
                
                TextField("test", text: $capturedText)
                { isEditing in
                    
                } onCommit: {
                    UserDefaults.standard.set(capturedText, forKey: "fduhole_token")
                    fduholeLoginInfo.token = capturedText
                }
                .textContentType(.oneTimeCode)
            }
            .onAppear() {
                connectionReachable = wcDelegate().sendString(text: "get_token")
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
