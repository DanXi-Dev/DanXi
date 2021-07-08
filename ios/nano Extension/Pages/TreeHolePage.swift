//
//  TreeHole.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/6/26.
//

import SwiftUI

struct TreeHolePage: View {
    @EnvironmentObject var fduholeLoginInfo: WatchSessionDelegate
    @State private var discussions = [THDiscussion]()
    @State private var currentPage = 1
    @State private var endReached = false
    @State private var error: String? = nil
    
    // Scroll Position Indicator
    @State private var isLoading = true
    
    func refreshDiscussions() {
        currentPage = 1
        isLoading = true
        loadDiscussions(token: fduholeLoginInfo.token, page: currentPage, sortOrder: SortOrder.last_updated) {(T: [THDiscussion]?, errorString: String?) -> Void in
            error = errorString
            if (errorString == nil) {
                discussions = T!
                isLoading = false
            }
        }
    }
    
    func loadNextPage() {
        currentPage += 1
        if (!isLoading) {
            isLoading = true
            loadDiscussions(token: fduholeLoginInfo.token, page: currentPage, sortOrder: SortOrder.last_updated) {(T: [THDiscussion]?, errorString: String?) -> Void in
                error = errorString
                if (errorString == nil) {
                    if (T!.isEmpty) {
                        endReached = true
                    }
                    discussions.append(contentsOf: T!)
                    isLoading = false
                }
            }
        }
    }
    
    var body: some View {
        if (error == nil) {
            if (discussions.isEmpty) {
                List {
                    ProgressView()
                }
                .navigationTitle("treehole")
                .onAppear(perform: refreshDiscussions)
            }
            else {
                List {
                    Button("refresh") {
                        refreshDiscussions()
                    }
                    ForEach(discussions) { discussion in
                        VStack {
                            ZStack {
                                THPostView(discussion: discussion)
                                NavigationLink(destination: TreeHoleDetailsPage(replies: discussion.posts)) {
                                    EmptyView()
                                }
                            }
                        }
                    }
                    if(!endReached) {
                        ProgressView()
                            .onAppear(perform: loadNextPage)
                    }
                    else {
                        Text("end_reached")
                    }
                }
                .navigationTitle("treehole")
            }
        }
        else {
            ErrorView(errorInfo: error ?? "Unknown Error")
                .environmentObject(fduholeLoginInfo)
                .onTapGesture {
                    refreshDiscussions()
                }
        }
    }
}

struct ErrorView: View {
    var errorInfo: String
    @EnvironmentObject var fduholeLoginInfo: WatchSessionDelegate
    
    var body: some View {
        VStack {
            Image(systemName: "xmark.octagon")
                .foregroundColor(.accentColor)
                .imageScale(.large)
            Text(NSLocalizedString("error", comment: "") + "\n\(errorInfo)")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("retry_login") {
                fduholeLoginInfo.token = ""
                UserDefaults.standard.removeObject(forKey: KEY_FDUHOLE_TOKEN)
            }
        }
    }
}

struct TreeHole_Previews: PreviewProvider {
    static var previews: some View {
        TreeHolePage()
    }
}
