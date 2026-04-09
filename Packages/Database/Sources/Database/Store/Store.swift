// © 2026 Aung Ko Min

import Core
import Foundation
import SwiftData
import XUI

public final actor Store: Sendable {
    public static let shared: Store = .init()

    public var appContainer: AppContainer? = nil
    public var modelContainer: ModelContainer? {
        appContainer?.modelContainer
    }

    public var msgStore: StoreModelActor<PMsg>? = nil
    public var contactStore: StoreModelActor<PContact>? = nil
    public var groupStore: StoreModelActor<PGroup>? = nil
    public var conversationPropertiesStore: StoreModelActor<PConversationProperties>? = nil

    public init() {}

    public func hasSetUp(for id: String) -> Bool {
        modelContainer?.configurations.contains(
            where: { $0.name == id },
        ) == true
    }

    public func start(with id: String) {
        if let configurations = appContainer?.modelContainer.configurations,
           configurations.contains(
               where: { $0.name == id },
           )
        {
            return
        }
        log("Store started with id: \(id)")
        let appContainer = AppContainer(migrationPlan: nil, id: id)
        let modelContainer = appContainer.modelContainer
        let context = ModelContext(modelContainer)
        context.autosaveEnabled = false
        let modelExecutor = DefaultSerialModelExecutor(modelContext: context)
        msgStore = .init(
            modelContainer: modelContainer,
            modelExecutor: modelExecutor,
        )
        contactStore = .init(
            modelContainer: modelContainer,
            modelExecutor: modelExecutor,
        )
        groupStore = .init(
            modelContainer: modelContainer,
            modelExecutor: modelExecutor,
        )
        conversationPropertiesStore = .init(
            modelContainer: modelContainer,
            modelExecutor: modelExecutor,
        )
        self.appContainer = appContainer
    }

    public func destory() {
        try? modelContainer?.erase()
        appContainer = nil
        msgStore = nil
        contactStore = nil
        groupStore = nil
        conversationPropertiesStore = nil
    }
}
