//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Foundation

@inlinable
public func log(
    _ object: (some Any)?,
    filename: String = #file,
    line: Int = #line,
    function _: String = #function
) {
    #if DEBUG
    guard let object else { return }
    let file = (filename as NSString).lastPathComponent
    print("\("✅") \(file)|\(line)\n\(object)")
    #endif
}
