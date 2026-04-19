//
//  Dictionary++.swift
//  FCM_V1
//
//  Created by Aung Ko Min on 18/4/26.
//

import Foundation

extension Dictionary where Key == String, Value == String {
    public static func encode<T: Codable>(_ value: T) -> [String: String] {
        guard
            let data = try? JSONEncoder().encode(value),
            let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String]
        else { return [:] }
        return dict
    }
}
