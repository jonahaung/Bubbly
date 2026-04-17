// © 2026 Aung Ko Min

import UIKit

enum PlaygroundModels {
    enum FetchFromLocalDataStore {
        struct Request {}

        struct Response {}

        struct ViewModel {
            var exampleTranslation: String? = nil
        }
    }

    enum FetchFromRemoteDataStore {
        struct Request {}

        struct Response {
            var exampleVariable: String? = nil
        }

        struct ViewModel {
            var exampleVariable: String? = nil
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
            var exampleVariable: String? = nil
        }

        struct Response {
            var error: PlaygroundError? = nil
        }

        struct ViewModel {
            var error: PlaygroundError? = nil
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
        var message: String? = nil

        init(type: T) {
            self.type = type
        }
    }
}
