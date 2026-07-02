//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import UIKit

extension UIImage {
    convenience init?(contentsOf url: URL) {
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        self.init(data: data)
    }
}
