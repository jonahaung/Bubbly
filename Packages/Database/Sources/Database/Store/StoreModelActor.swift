// © 2026 Aung Ko Min

import Foundation
import SwiftData

public actor StoreModelActor<T: SendableTransformable>: ModelActor where T.UID == String,
    T.SendableType.UID == String
{
    public let modelExecutor: any ModelExecutor
    public let modelContainer: ModelContainer

    private var context: ModelContext {
        modelExecutor.modelContext
    }

    private var saveTask: Task<Void, Never>?

    public init(
        modelContainer: ModelContainer,
        modelExecutor: ModelExecutor,
    ) {
        self.modelContainer = modelContainer
        self.modelExecutor = modelExecutor
    }

    public func insert(_ data: T.SendableType) throws {
        if try exists(uid: data.uid) {
            try updateAndSave(uid: data.uid) { model in
                model.update(from: data)
            }
            return
        }
        context.insert(T(from: data))
        try save()
    }

    public func fetch(uid: String) throws -> T.SendableType? {
        try getModel(for: uid)?.toSendable()
    }

    public func fetch(_ descriptor: FetchDescriptor<T>) throws -> [T.SendableType] {
        try context
            .fetch(descriptor)
            .map { $0.toSendable() }
    }

    public func fetchAll() throws -> [T.SendableType] {
        try fetch(.init())
    }

    public func exists(uid: String) throws -> Bool {
        try fetchCount(for: uid) > 0
    }

    public func fetchCount(for uid: String) throws -> Int {
        try fetchCount(
            .init(
                predicate: #Predicate {
                    $0.uid == uid
                },
            ),
        )
    }

    public func fetchCount(_ descriptor: FetchDescriptor<T>) throws -> Int {
        try context.fetchCount(descriptor)
    }

    // MARK: - Update

    public func updateAndSave<Result: Sendable>(
        uid: String,
        _ update: sending (inout T) -> Result,
    ) throws
        -> Result?
    {
        guard var model = try getModel(for: uid) else {
            return nil
        }

        let result = update(&model)
        try save()
        return result
    }

    public func updateAndSaveDebounced<Result: Sendable>(
        uid: String,
        _ update: @escaping (inout T)
            -> Result,
    ) throws -> Result? {
        guard var model = try getModel(for: uid) else {
            return nil
        }

        let result = update(&model)
        saveDebounced()
        return result
    }

    // MARK: - Delete

    public func delete(id: PersistentIdentifier) throws {
        context.delete(context.model(for: id))
        try save()
    }

    public func delete(uid: String) throws {
        guard let model = try getModel(for: uid) else {
            return
        }

        try delete(id: model.persistentModelID)
    }

    public func delete(where predicate: Predicate<T>) throws {
        try context.delete(model: T.self, where: predicate)
        try save()
    }

    // MARK: - Save

    public func save() throws {
        if context.hasChanges {
            try context.save()
        }
    }

    public func saveDebounced(after delay: TimeInterval = 0.5) {
        saveTask?.cancel()

        saveTask = Task {
            try? await Task.sleep(for: .seconds(delay))

            guard !Task.isCancelled else {
                return
            }

            if context.hasChanges {
                try? context.save()
            }

            saveTask = nil
        }
    }

    // MARK: - Private Helpers

    private func getModel(for uid: String) throws -> T? {
        var descriptor = FetchDescriptor<T>(
            predicate: #Predicate {
                $0.uid == uid
            },
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
