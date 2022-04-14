//
//  THPostDetailView.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/7/1.
//

import SwiftUI

struct THPostDetailView: View {
    var reply: OTFloor
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(reply.anonyname)")
            Text(preprocessTextForHtmlAndImage(text:reply.content))
        }
        .padding()
    }
}

struct THPostDetailView_Previews: PreviewProvider {
    static var previews: some View {
        THPostDetailView(reply: OTFloor(floor_id: 1, hole_id: 2, like: 3, content: "he", anonyname: "MMM", time_updated: "", time_created: "", deleted: false, is_me: false, liked: false, fold: []))
    }
}
