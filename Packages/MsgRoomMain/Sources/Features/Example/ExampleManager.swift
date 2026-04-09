//
//  Created by Aung Ko Min on 9/4/26.
//

import Observation

@MainActor
@Observable
final class ExampleManager {
    private(set) var isLoading = false
    private(set) var error: String?

    func setLoading(_ value: Bool) {
        isLoading = value
    }

    func setError(_ value: String?) {
        error = value
    }
}
