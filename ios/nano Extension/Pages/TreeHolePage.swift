//
//  TreeHole.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/6/26.
//

import SwiftUI

struct TreeHolePage: View {
    @EnvironmentObject var fduholeLoginInfo: wcDelegate
    @State private var discussions = [THDiscussion]()
    @State private var currentPage = 1
    @State private var endReached = false
    
    // Scroll Position Indicator
    @State private var isLoading = true
    
    func refreshDiscussions() {
        currentPage = 1
        isLoading = true
        loadDiscussions(token: fduholeLoginInfo.token, page: currentPage, sortOrder: SortOrder.last_updated) {(T: [THDiscussion]) -> Void in discussions = T
            isLoading = false
        }
    }
    
    func loadNextPage() {
        currentPage += 1
        if (!isLoading) {
            isLoading = true
            loadDiscussions(token: fduholeLoginInfo.token, page: currentPage, sortOrder: SortOrder.last_updated) {(T: [THDiscussion]) -> Void in
                if (T.isEmpty) {
                    endReached = true
                }
                discussions.append(contentsOf: T)
                isLoading = false
            }
        }
    }
    
    var body: some View {
        if (discussions.isEmpty) {
            List {
                ProgressView()
            }
            .navigationTitle("treehole")
            .onAppear(perform: refreshDiscussions)
        }
        else {
            VStack {
                List(discussions) { discussion in
                    VStack {
                        ZStack {
                            THPostView(discussion: discussion)
                            NavigationLink(destination: TreeHoleDetailsPage(replies: discussion.posts)) {
                                EmptyView()
                            }
                        }
                        if(discussion == discussions.last && !endReached) {
                            ProgressView()
                                .onAppear(perform: loadNextPage)
                        }
                    }
                }
                //ProgressView()
                //.onAppear(perform: loadNextPage)
            }
            .navigationTitle("treehole")
        }
    }
}

struct TreeHole_Previews: PreviewProvider {
    static var previews: some View {
        TreeHolePage()
    }
}
