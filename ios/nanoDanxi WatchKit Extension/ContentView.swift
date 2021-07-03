//
//  ContentView.swift
//  nanoDanxi WatchKit Extension
//
//  Created by Kavin Zhao on 2021/7/3.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var fduholeLoginInfo: fduholeTokenProvider
    
    var body: some View {
        
        if (fduholeLoginInfo.token == "") {
            VStack {
                ProgressView()
                Text("gettingtoken")
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
