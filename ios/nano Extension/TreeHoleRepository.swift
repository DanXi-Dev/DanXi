//
//  TreeHoleRepository.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/6/26.
//

import Foundation

let BASE_URL = "https://api.fduhole.com"

func loadHoles<T: Decodable>(token: String, startTime: String?, divisionId: Int?, completion: @escaping (T?, _ error: String?) -> Void) -> Void {
    var components = URLComponents(string: BASE_URL + "/holes")!
    components.queryItems = [
        URLQueryItem(name: "start_time", value: startTime),
        URLQueryItem(name: "division_id", value: String(divisionId ?? 1))
    ]
    components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
    var request = URLRequest(url: components.url!)
    request.httpMethod = "GET"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if (error == nil) {
            if let data = data {
                if let decodedResponse = try? JSONDecoder().decode(T.self, from: data) {
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

func loadDivisions<T: Decodable>(token: String, completion: @escaping (T?, _ error: String?) -> Void) -> Void {
    var components = URLComponents(string: BASE_URL + "/divisions")!
    components.queryItems = []
    components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
    var request = URLRequest(url: components.url!)
    request.httpMethod = "GET"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if (error == nil) {
            if let data = data {
                if let decodedResponse = try? JSONDecoder().decode(T.self, from: data) {
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

func loadFloors<T: Decodable>(token: String, page: Int, discussionId: Int, completion: @escaping (T?, _ error: String?) -> Void) -> Void {
    var components = URLComponents(string: BASE_URL + "/floors")!
    components.queryItems = [
        URLQueryItem(name: "start_floor", value: String((page-1)*10)),
        URLQueryItem(name: "hole_id", value: String(discussionId))
    ]
    components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
    var request = URLRequest(url: components.url!)
    request.httpMethod = "GET"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    URLSession.shared.dataTask(with: request) {
        data, response, error in
        if (error == nil) {
            if let data = data {
                if let decodedResponse = try? JSONDecoder().decode(T.self, from: data) {
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
