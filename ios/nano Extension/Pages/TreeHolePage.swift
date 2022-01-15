//
//  TreeHole.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/6/26.
//

import SwiftUI

let DUMMY_DIVISION = OTDivision(division_id: 1, name: "FDUHole", description: "", pinned: nil)

struct TreeHolePage: View {
    @EnvironmentObject var fduholeLoginInfo: WatchSessionDelegate
    @State private var currentDivision = DUMMY_DIVISION
    @State private var divisions = [OTDivision]()
    @State private var holes = [OTHole]()
    @State private var endReached = false
    @State private var error: String? = nil
    
    // Scroll Position Indicator
    @State private var isLoading = true
    
    func refreshDiscussions() {
        isLoading = true
        loadDivisions(token: fduholeLoginInfo.token) {(T: [OTDivision]?, errorString: String?) -> Void in
            error = errorString
            if (errorString == nil) {
                divisions = T!
                if (currentDivision == DUMMY_DIVISION) {
                    currentDivision = divisions.first(where: { element in
                        element.division_id == 1
                    }) ?? DUMMY_DIVISION
                }
                
                loadHoles(token: fduholeLoginInfo.token, startTime: nil, divisionId: currentDivision.division_id) {(T: [OTHole]?, errorString: String?) -> Void in
                    error = errorString
                    if (errorString == nil) {
                        holes = T!
                        isLoading = false
                    }
                }
            }
        }
    }
    
    func loadNextPage() {
        if (!isLoading) {
            isLoading = true
            loadHoles(token: fduholeLoginInfo.token, startTime: holes.last?.time_updated, divisionId: currentDivision.division_id) {(T: [OTHole]?, errorString: String?) -> Void in
                error = errorString
                if (errorString == nil) {
                    if (T!.isEmpty) {
                        endReached = true
                    }
                    holes.append(contentsOf: T!)
                    isLoading = false
                }
            }
        }
    }
    
    var body: some View {
        if (error == nil) {
            if (holes.isEmpty) {
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
                    Picker("division", selection: $currentDivision) {
                        ForEach(divisions, id: \.self) {division in
                            Text("\(division.name) - \(division.description)")
                        }
                    }
                    .onChange(of: currentDivision) { newDivision in
                        endReached = false
                        refreshDiscussions()
                    }
                    ForEach(holes) { discussion in
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
