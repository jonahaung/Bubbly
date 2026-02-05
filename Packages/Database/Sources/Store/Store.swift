//
//  Store.swift
//
//  Created by Aung Ko Min on 22/7/24.
//

import Foundation
import SwiftData
import XUI

public actor Store {
    public static let shared = Store()

    public var appContainer: AppContainer?
    public var modelContainer: ModelContainer? { appContainer?.modelContainer }

    public var msgStore: StoreModelActor<PMsg>?
    public var contactStore: StoreModelActor<PContact>?
    public var groupStore: StoreModelActor<PGroup>?
    public var conversationPropertiesStore: StoreModelActor<PConversationProperties>?

    public init() {}

	public func hasSetUp(for id: String) -> Bool {
		guard let appContainer else {
			return false
		}
		return appContainer.modelContainer.configurations.contains(
			where: { $0.name == id })

	}

    public func start(with id: String) {
		if let configurations = appContainer?.modelContainer.configurations, configurations.contains(
			where: { $0.name == "currentUserID"}) {
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
        conversationPropertiesStore = .init(
            modelContainer: modelContainer,
            modelExecutor: modelExecutor
        )
        self.appContainer = appContainer
    }

	public func destory() {
		appContainer = nil
		msgStore = nil
		contactStore = nil
		groupStore = nil
		conversationPropertiesStore = nil
	}
}
