import Core
import Foundation
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
        let schema = Schema(AppSchemaV1.models)
        let configuration = ModelConfiguration(
            id,
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            groupContainer: .identifier(AppInformation.groupID)
        )
        do {
            try Self.prepareStoreDirectory()
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

    private static func prepareStoreDirectory() throws {
        guard let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppInformation.groupID
        ) else {
            throw CocoaError(.fileNoSuchFile)
        }

        let applicationSupportURL = groupURL
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)

        try FileManager.default.createDirectory(
            at: applicationSupportURL,
            withIntermediateDirectories: true
        )
    }
}
