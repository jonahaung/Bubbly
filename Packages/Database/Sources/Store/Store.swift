//
//  Store.swift
//
//  Created by Aung Ko Min on 22/7/24.
//

import Foundation
import SwiftData

public final class Store: Sendable {
    public static let shared = Store()

    public let appContainer: AppContainer
    public var modelContainer: ModelContainer { appContainer.modelContainer }

    public let msgStore: StoreModelActor<PMsg>
    public let contactStore: StoreModelActor<PContact>
    public let groupStore: StoreModelActor<PGroup>

    public init() {
        let appContainer = AppContainer(migrationPlan: nil)
        let modelContainer = appContainer.modelContainer
        let context = ModelContext(modelContainer)
        context.autosaveEnabled = false
        let modelExecutor = DefaultSerialModelExecutor(modelContext: context)
        msgStore = .init(
            modelContainer: modelContainer,
            modelExecutor: modelExecutor
        )
        contactStore = .init(
            modelContainer: modelContainer,
            modelExecutor: modelExecutor
        )
        groupStore = .init(
            modelContainer: modelContainer,
            modelExecutor: modelExecutor
        )
        self.appContainer = appContainer
    }
}
