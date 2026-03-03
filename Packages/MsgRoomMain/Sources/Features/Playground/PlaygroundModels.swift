//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import UIKit

enum PlaygroundModels {
    enum FetchFromLocalDataStore {
        struct Request {}

        struct Response {}

        struct ViewModel {
            var exampleTranslation: String?
        }
    }

    enum FetchFromRemoteDataStore {
        struct Request {}

        struct Response {
            var exampleVariable: String?
        }

        struct ViewModel {
            var exampleVariable: String?
        }
    }

    enum TrackAnalytics {
        struct Request {
            var event: AnalyticsEvents
        }

        struct Response {}

        struct ViewModel {}
    }

    enum PerformPlayground {
        struct Request {
            var exampleVariable: String?
        }

        struct Response {
            var error: PlaygroundError?
        }

        struct ViewModel {
            var error: PlaygroundError?
        }
    }

    typealias AnalyticsEvents = ExampleAnalyticsEvents
    typealias PlaygroundError = Error<PlaygroundErrorType>

    enum ExampleAnalyticsEvents {
        case screenView
    }

    enum PlaygroundErrorType {
        case emptyExampleVariable
        case networkError
    }

    struct Error<T> {
        var type: T
        var message: String?

        init(type: T) {
            self.type = type
        }
    }
}
