//  AppContainer.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import Core
import SwiftData
import Foundation

// MARK: - AppSchemaV1

public enum AppSchemaV1: VersionedSchema {
    public static let versionIdentifier: Schema.Version = .init(1, 0, 0)
    public static var models: [any PersistentModel.Type] {
        [
            PContact.self,
            PMsg.self,
            PGroup.self,
            PConversationProperties.self
        ]
    }
}

// MARK: - AppSchemaMigrationPlan

public enum AppSchemaMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [
            AppSchemaV1.self
        ]
    }

    public static var stages: [MigrationStage] {
        []
    }
}

// MARK: - AppContainer

public final class AppContainer: Sendable {
    public let modelContainer: ModelContainer

    public init(migrationPlan: (any SchemaMigrationPlan.Type)? = nil, id: String?) {
        let schema = Schema(AppSchemaV1.models)
        let configuration = ModelConfiguration(
            id,
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            groupContainer: .identifier(AppInformation.groupID),
            cloudKitDatabase: .none
        )
        do {
            modelContainer = try ModelContainer(
                for: schema,
                migrationPlan: nil,
                configurations: configuration
            )
        } catch {
            if migrationPlan == nil,
               let legacyModelContainer = try? ModelContainer(
                   for: schema,
                   configurations: configuration
               )
            {
                modelContainer = legacyModelContainer
                return
            }
            fatalError(error.localizedDescription)
        }
    }
}
