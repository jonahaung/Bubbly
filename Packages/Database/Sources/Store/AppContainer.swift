//
//  Schema1.swift
//  Database
//
//  Created by Aung Ko Min on 14/7/25.
//

import SwiftData
import Core

public final class AppContainer: Sendable {

	public let modelContainer: ModelContainer

	public init(migrationPlan: (any SchemaMigrationPlan.Type)? = nil) {
		let schema: Schema = Schema(
			[
				PConversation.self,
				PContact.self,
				PMsg.self
			]
		)
		let configuration = ModelConfiguration(
			schema: schema,
			isStoredInMemoryOnly: false,
			allowsSave: true,
			groupContainer: .identifier(AppInformation.groupID),
			// cloudKitDatabase: .private(AppInformation.iCloudID)
		)
		do {
			let modelContainer = try ModelContainer(
				for: schema,
				migrationPlan: migrationPlan,
				configurations: configuration
			)
			self.modelContainer = modelContainer
		} catch {
			fatalError(error.localizedDescription)
		}
	}
}
