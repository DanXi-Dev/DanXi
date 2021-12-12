//
//  TreeHoleRepository.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/6/26.
//

import Foundation

let BASE_URL = "https://hole.hath.top"

func loadDiscussions<T: Decodable>(token: String, page: Int, sortOrder: SortOrder, completion: @escaping (T?, _ error: String?) -> Void) -> Void {
    var components = URLComponents(string: BASE_URL + "/holes")!
    components.queryItems = [
        URLQueryItem(name: "page", value: String(page)),
        URLQueryItem(name: "order", value: sortOrder.getString())
    ]
    components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
    var request = URLRequest(url: components.url!)
    request.httpMethod = "GET"
    request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if (error == nil) {
            if let data = data {
                if let decodedResponse = try? JSONDecoder().decode(T.self, from: data) {
                    // we have good data – go back to the main thread
                    completion(decodedResponse, nil)
                    return
                }
            }
        }
        else {
            completion(nil, error!.localizedDescription)
        }
    }.resume()
}

func loadReplies<T: Decodable>(token: String, page: Int, discussionId: Int, completion: @escaping (T?, _ error: String?) -> Void) -> Void {
    var components = URLComponents(string: BASE_URL + "/posts/")!
    components.queryItems = [
        URLQueryItem(name: "page", value: String(page)),
        URLQueryItem(name: "id", value: String(discussionId))
    ]
    components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
    var request = URLRequest(url: components.url!)
    request.httpMethod = "GET"
    request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")
    
    URLSession.shared.dataTask(with: request) {
        data, response, error in
        if (error == nil) {
            if let data = data {
                if let decodedResponse = try? JSONDecoder().decode(T.self, from: data) {
                    // we have good data – go back to the main thread
                    completion(decodedResponse, nil)
                    return
                }
            }
        }
        else {
            completion(nil, error!.localizedDescription)
        }
    }.resume()
}


enum TreeHoleError: Error {
    case insecureConnection
    case unauthorized
    case connectionFailed
    case invalidResponse
}

enum SortOrder {
    case last_updated
    case last_created
}

extension SortOrder {
    public func getString() -> String {
        switch (self) {
        case .last_created:
            return "last_created"
        case .last_updated:
            return "last_updated"
        }
    }
}
