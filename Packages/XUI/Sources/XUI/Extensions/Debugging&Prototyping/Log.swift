//
//  Log.swift
//  RoomRentalDemo
//
//  Created by Aung Ko Min on 19/1/23.
//

import Foundation

@inlinable
public func log(_ object: (some Any)?,
                filename: String = #file,
                line: Int = #line,
                function _: String = #function)
{
	#if DEBUG
		guard let object else { return }
		let file = (filename as NSString).lastPathComponent
		print("\(file), \(line)\t\t\t\t\t\t\t\t\t\t\t\t\t\(object)")
	#endif
}
