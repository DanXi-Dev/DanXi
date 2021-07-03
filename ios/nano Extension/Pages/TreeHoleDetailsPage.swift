//
//  TreeHoleDetailsPage.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/7/1.
//

import SwiftUI

struct TreeHoleDetailsPage: View {
    @State var replyList: [THReply]
    @State var currentPage: Int = 1
    @State var isLoading = false
    @State var endReached = false
    @EnvironmentObject var fduholeLoginInfo: fduholeTokenProvider
    
    init(replies: [THReply]) {
        replyList = replies
    }
    
    func loadMoreReplies() {
        currentPage += 1
        if (!isLoading) {
            isLoading = true
            loadReplies(token: fduholeLoginInfo.token, page: currentPage, discussionId: replyList.first!.discussion) { (T: [THReply]) -> Void in
                if (T.isEmpty) {
                    endReached = true
                }
                replyList.append(contentsOf: T)
                isLoading = false
            }
        }
    }
    
    var body: some View {
        List(replyList) { reply in
            VStack {
                THPostDetailView(reply: reply)
                Spacer()
                if (reply == replyList.last && !endReached) {
                    ProgressView()
                        .onAppear(perform: loadMoreReplies)
                }
            }
        }
        .navigationTitle("#\(replyList.first!.discussion)")
    }
}

struct TreeHoleDetailsPage_Previews: PreviewProvider {
    static var previews: some View {
        TreeHoleDetailsPage(replies: [THReply(id: 456, discussion: 123, content: "HelloWorld", username: "Demo", date_created: "xxx", reply_to: nil, is_me: false), THReply(id: 456, discussion: 123, content: "HelloWorld", username: "Demo", date_created: "xxx", reply_to: nil, is_me: false)])
    }
}
