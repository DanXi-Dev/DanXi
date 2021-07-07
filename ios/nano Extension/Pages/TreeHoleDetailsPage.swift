//
//  TreeHoleDetailsPage.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/7/1.
//

import SwiftUI

struct TreeHoleDetailsPage: View {
    @State private var replyList: [THReply]
    @State private var currentPage: Int = 1
    @State private var isLoading = false
    @State private var endReached = false
    @State private var error: String? = nil
    @EnvironmentObject var fduholeLoginInfo: WatchSessionDelegate
    
    init(replies: [THReply]) {
        replyList = replies
    }
    
    func loadMoreReplies() {
        currentPage += 1
        if (!isLoading) {
            isLoading = true
            loadReplies(token: fduholeLoginInfo.token, page: currentPage, discussionId: replyList.first!.discussion) { (T: [THReply]?, errorString: String?) -> Void in
                error = errorString
                if (errorString == nil) {
                    if (T!.isEmpty) {
                        endReached = true
                    }
                    replyList.append(contentsOf: T!)
                    isLoading = false
                }
            }
        }
    }
    
    var body: some View {
        List {
            ForEach(replyList) { reply in
                THPostDetailView(reply: reply)
            }
            if (!endReached && error == nil) {
                ProgressView()
                    .onAppear(perform: loadMoreReplies)
            }
            else if (error != nil) {
                ErrorView(errorInfo: error!)
                    .onTapGesture {
                        loadMoreReplies()
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
