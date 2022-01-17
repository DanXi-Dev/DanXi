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

struct OTHole: Hashable, Codable, Identifiable {
    var id: Int {
        get {
            return self.hole_id
        }
    }
    
    let hole_id, division_id: Int
    let view, reply: Int?
    let floors: _OTFloors
    let time_created, time_updated: String
    let tags: [OTTag]?
}

struct _OTFloors: Hashable, Codable {
    let last_floor: OTFloor
    let prefetch: [OTFloor]
}

struct OTFloor: Hashable, Codable, Identifiable {
    var id: Int {
        get {
            return self.floor_id
        }
    }
    
    let floor_id, hole_id, like: Int
    let content, anonyname, time_updated, time_created: String
    let deleted, is_me, liked: Bool?
    let fold: [String]?
}

struct OTDivision: Hashable, Codable, Identifiable {
    var id: Int {
        get {
            return self.division_id
        }
    }
    
    let division_id: Int
    let name, description: String
    let pinned: [OTHole]?
}

struct OTTag: Hashable, Codable {
    let name: String
    let tag_id, temperature: Int
}
