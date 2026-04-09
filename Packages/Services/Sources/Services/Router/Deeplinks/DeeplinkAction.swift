//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Foundation

public enum DeeplinkAction: Sendable, Equatable {
    case selectTab(TabPath)
    case pushToNav(NavPath)
    case presentModel(NavPath)
    case sideEffect(SideEffect)

    public enum SideEffect: Sendable, Equatable, Hashable {
        case prepareForConversation(id: String)
        case prepareForContactDetails(id: String)
        case track(event: String, properties: [String: String])
        case requireAuth(reason: String?)
    }
}
