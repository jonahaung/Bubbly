//
//  File.swift
//  
//
//  Created by Aung Ko Min on 18/7/23.
//

import Foundation

public extension Data {

    init?(path: String) {
        try? self.init(contentsOf: URL(fileURLWithPath: path))
    }

    func write(path: String, options: Data.WritingOptions = []) {
        try? self.write(to: URL(fileURLWithPath: path), options: options)
    }
}
