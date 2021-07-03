//
//  ContentView.swift
//  nanoDanxi WatchKit Extension
//
//  Created by Kavin Zhao on 2021/7/3.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var fduholeLoginInfo: fduholeTokenProvider
    @State var connectionReachable = true;
    
    var body: some View {
        
        if (fduholeLoginInfo.token == "") {
            VStack {
                if (connectionReachable) {
                    ProgressView()
                    Text("gettingtoken")
                }
                else {
                    Text("iphoneunreachable")
                        .onTapGesture {
                            connectionReachable = fduholeTokenProvider().sendString(text: "get_token")
                        }
                }
            }
            .onAppear() {
                connectionReachable = fduholeTokenProvider().sendString(text: "get_token")
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
