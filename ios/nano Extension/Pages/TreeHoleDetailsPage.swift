//
//  TreeHoleDetailsPage.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/7/1.
//

import SwiftUI

struct TreeHoleDetailsPage: View {
    @State private var replyList: [OTFloor]
    @State private var currentPage: Int = 1
    @State private var isLoading = false
    @State private var endReached = false
    @State private var error: String? = nil
    @EnvironmentObject var fduholeLoginInfo: WatchSessionDelegate
    
    init(replies: [OTFloor]) {
        replyList = replies
    }
    
    func loadMoreReplies() {
        currentPage += 1
        if (!isLoading) {
            isLoading = true
            loadFloors(token: fduholeLoginInfo.token, page: currentPage, discussionId: replyList.first!.hole_id) { (T: [OTFloor]?, errorString: String?) -> Void in
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
                ErrorView(errorInfo: error ?? "Unknown Error")
                    .environmentObject(fduholeLoginInfo)
                    .onTapGesture {
                        loadMoreReplies()
                    }
            }
            else {
                Text("end_reached")
            }
        }
        .navigationTitle("#\(replyList.first!.hole_id)")
    }
}

struct TreeHoleDetailsPage_Previews: PreviewProvider {
    static var previews: some View {
        Text("too lazy to write preview")
    }
}
