//
//  THPostDetailView.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/7/1.
//

import SwiftUI

struct THPostDetailView: View {
    var reply: THReply
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("[\(reply.username)]")
            Text(preprocessTextForHtmlAndImage(text:reply.content))
        }
        .padding()
    }
}

struct THPostDetailView_Previews: PreviewProvider {
    static var previews: some View {
        THPostDetailView(reply: THReply(id: 456, discussion: 123, content: "HelloWorld", username: "Demo", date_created: "2021-01-01", reply_to: nil, is_me: false))
    }
}
