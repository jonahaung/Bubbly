//
//  StoreModelActor.swift
//  Database
//
//  Created by Aung Ko Min on 12/7/25.
//

import Foundation
import SwiftData

public actor StoreModelActor<Model>: ModelActor
    where Model: PersistentModel & CollectionDocument & SendableDocument,
    Model.SendableType: Sendable,
    Model.UID == String,
    Model.SendableType.UID == String
{
    public nonisolated let modelExecutor: any ModelExecutor
    public nonisolated let modelContainer: ModelContainer

    private var context: ModelContext {
        modelExecutor.modelContext
    }

    private var cached: Model?

    // Debounced save task
    private var saveTask: Task<
        Void,
        Never
    >?

    // MARK: - Init

    public init(
        modelContainer: ModelContainer,
        modelExecutor: ModelExecutor
    ) {
        self.modelContainer = modelContainer
        self.modelExecutor = modelExecutor
    }

    // MARK: - Create

    public func insert(
        _ data: Model.SendableType
    ) throws {
        guard try fetchCount(
            for: data.uid
        ) == 0 else {
            return
        }
        context
            .insert(
                Model(
                    from: data
                )
            )
        try save()
    }

    // MARK: - Read

    public func fetch(
        id: PersistentIdentifier
    ) -> Model.SendableType? {
        self[
            id,
            as: Model.self
        ]?.toSendable()
    }

    public func fetch(
        uid: String
    ) throws -> Model.SendableType? {
        try getModel(
            for: uid
        )?
            .toSendable()
    }

    public func fetch(
        _ descriptor: FetchDescriptor<Model>
    ) throws -> [Model.SendableType] {
        try context
            .fetch(
                descriptor
            )
            .map {
                $0.toSendable()
            }
    }

    public func fetchAll() throws -> [Model.SendableType] {
        try fetch(
            .init()
        )
    }

    public func exists(
        uid: String
    ) throws -> Bool {
        try fetchCount(
            for: uid
        ) > 0
    }

    public func fetchCount(
        for uid: String
    ) throws -> Int {
        try fetchCount(
            .init(
                predicate: #Predicate {
                    $0.uid == uid
                })
        )
    }

    public func fetchCount(
        _ descriptor: FetchDescriptor<Model>
    ) throws -> Int {
        try context
            .fetchCount(
                descriptor
            )
    }

    // MARK: - Update

    public func updateAndSave<Result: Sendable>(
        uid: String,
        _ update: sending (
            inout Model
        ) -> Result
    ) throws -> Result? {
        guard var model = try getModel(
            for: uid
        ) else {
            return nil
        }
        let result = update(
            &model
        )
        try save()
        return result
    }

    public func updateAndSaveDebounced<Result: Sendable>(
        uid: String,
        _ update: @escaping (
            inout Model
        ) -> Result
    ) throws -> Result? {
        guard var model = try getModel(
            for: uid
        ) else {
            return nil
        }
        let result = update(
            &model
        )
        saveDebounced()
        return result
    }

    // MARK: - Delete

    public func delete(
        id: PersistentIdentifier
    ) throws {
        guard let model = self[
            id,
            as: Model.self
        ] else {
            return
        }
        cached = nil
        context
            .delete(
                model
            )
        try save()
    }

    public func delete(
        uid: String
    ) throws {
        guard let model = try getModel(
            for: uid
        ) else {
            return
        }
        cached = nil
        context
            .delete(
                model
            )
        try save()
    }

    public func delete(
        where predicate: Predicate<Model>
    ) throws {
        try context
            .delete(
                model: Model.self,
                where: predicate
            )
        try save()
    }

    // MARK: - Save

    public func save() throws {
        try context
            .save()
    }

    public func saveDebounced(
        after delay: TimeInterval = 1
    ) {
        saveTask?
            .cancel()
        saveTask = Task {
            try? await Task
                .sleep(
                    for: .seconds(
                        delay
                    )
                )
            guard !Task.isCancelled else {
                return
            }
            try? context
                .save()
            saveTask = nil
        }
    }

    // MARK: - Private Helpers

    private func getModel(
        for uid: String
    ) throws -> Model? {
        if cached?.uid == uid {
            return cached
        }
        let descriptor = FetchDescriptor<Model>(
            predicate: #Predicate {
                $0.uid == uid
            })
        cached = try context
            .fetch(
                descriptor
            ).first
        return cached
    }
}
