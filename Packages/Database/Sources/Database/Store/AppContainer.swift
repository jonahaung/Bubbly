//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Core
import SwiftData

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

public final class AppContainer: Sendable {
    public let modelContainer: ModelContainer

    public init(migrationPlan: (any SchemaMigrationPlan.Type)? = nil, id: String?) {
        let schema = Schema(
            AppSchemaV1.models
        )
        let configuration = ModelConfiguration(
            id,
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            groupContainer: .identifier(AppInformation.groupID)
            // cloudKitDatabase: .private(AppInformation.iCloudID)
        )
        do {
            let modelContainer = try ModelContainer(
                for: schema,
                migrationPlan: migrationPlan ?? AppSchemaMigrationPlan.self,
                configurations: configuration
            )
            self.modelContainer = modelContainer
        } catch {
            if migrationPlan == nil,
               let legacyModelContainer = try? ModelContainer(
                   for: schema,
                   configurations: configuration
               ) {
                modelContainer = legacyModelContainer
                return
            }
            fatalError(error.localizedDescription)
        }
    }
}
