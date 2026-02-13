import CoreData
import Foundation

public final class LocalStorage: LocalStorageProtocol {
	private let persistentContainer: NSPersistentContainer

	public init(modelName: String = "ChatModel") {
		persistentContainer = NSPersistentContainer(name: modelName)
		persistentContainer.loadPersistentStores { _, error in
			if let error {
				fatalError("Unable to load persistent stores: \(error)")
			}
		}

		persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
	}

	private var context: NSManagedObjectContext {
		persistentContainer.viewContext
	}
}
