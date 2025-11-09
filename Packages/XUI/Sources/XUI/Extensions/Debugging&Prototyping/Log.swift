//
//  Log.swift
//  RoomRentalDemo
//
//  Created by Aung Ko Min on 19/1/23.
//

import Foundation

public func Log(_ object: (some Any)?, filename: String = #file, line: Int = #line, funcname _: String = #function) {
    #if DEBUG
        guard let object else { return }
        print("\(filename.components(separatedBy: "/").last ?? ""), \(line)\t\t\t\t\t\t\t\t\t\t\t\t\t\(object)")
    #endif
}
