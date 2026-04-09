//
//  Created by Aung Ko Min on 9/4/26.
//

import UIKit

enum ExampleModels {

    enum FetchFromLocalDataStore {
        struct Request {
        }

        struct Response {
        }

        struct ViewModel {
            var exampleTranslation: String?
        }
    }

    enum FetchFromRemoteDataStore {
        struct Request {
        }

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

        struct Response {
        }

        struct ViewModel {
        }
    }

    enum PerformExample {
        struct Request {
            var exampleVariable: String?
        }

        struct Response {
            var error: ExampleError?
        }

        struct ViewModel {
            var error: ExampleError?
        }
    }

    typealias AnalyticsEvents = ExampleAnalyticsEvents
    typealias ExampleError = Error<ExampleErrorType>

    enum ExampleAnalyticsEvents {
        case screenView
    }

    enum ExampleErrorType {
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
