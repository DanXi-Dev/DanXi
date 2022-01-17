//
//  Discussion.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/6/26.
//

import Foundation

class FduholeLoginInfo: ObservableObject {
    @Published var token: String = ""
}

struct THDiscussion: Hashable, Codable, Identifiable {
    let id, count: Int
    let posts: [THReply]
    let last_post: THReply?
    let is_folded: Bool
    let date_created, date_updated: String
    let tag: [THTag]?
}

struct THReply: Hashable, Codable, Identifiable {
    let id, discussion: Int
    let content, username, date_created: String
    let reply_to: Int?
    let is_me: Bool?
}

struct THTag: Hashable, Codable {
    let name, color: String
    let count: Int
}
