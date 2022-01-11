//
//  TreeHole.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/6/26.
//

import SwiftUI

struct TreeHolePage: View {
    @EnvironmentObject var fduholeLoginInfo: WatchSessionDelegate
    @State private var divisionId = 1
    @State private var discussions = [OTHole]()
    @State private var endReached = false
    @State private var error: String? = nil
    
    // Scroll Position Indicator
    @State private var isLoading = true
    
    func refreshDiscussions() {
        isLoading = true
        loadHoles(token: fduholeLoginInfo.token, startTime: discussions.last!.time_updated, divisionId: divisionId) {(T: [OTHole]?, errorString: String?) -> Void in
            error = errorString
            if (errorString == nil) {
                discussions = T!
                isLoading = false
            }
        }
    }
    
    func loadNextPage() {
        if (!isLoading) {
            isLoading = true
            loadHoles(token: fduholeLoginInfo.token, startTime: discussions.last!.time_updated, divisionId: divisionId) {(T: [OTHole]?, errorString: String?) -> Void in
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
                    Button(action: refreshDiscussions) {
                        HStack {
                            Text("refresh")
                            if (isLoading) {
                                ProgressView()
                            }
                        }
                    }
                    ForEach(discussions) { discussion in
                        ZStack(alignment: .leading) {
                            THPostView(discussion: discussion)
                            NavigationLink(destination: TreeHoleDetailsPage(replies: discussion.floors.prefetch)) {
                                EmptyView()
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
