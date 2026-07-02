//  AsyncOrderedStream.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import Foundation

public enum AsyncOrderedStream {

    @discardableResult
    public static func mapOrdered<Input: Sendable, Output: Sendable>(
        inputs: [Input],
        maxConcurrentTasks: Int = ProcessInfo.processInfo.activeProcessorCount,
        transform: @Sendable @escaping (Input) async throws -> Output
    ) async throws -> [Output] {

        guard !inputs.isEmpty else { return [] }

        return try await withThrowingTaskGroup(of: (Int, Output).self) { group in
            var results = Array<Output?>(repeating: nil, count: inputs.count)

            let initial = min(maxConcurrentTasks, inputs.count)

            // seed
            for i in 0..<initial {
                addTask(at: i, in: &group, inputs: inputs, transform: transform)
            }

            var next = initial

            while let (index, output) = try await group.next() {

                try Task.checkCancellation() // 🔥 important

                results[index] = output

                if next < inputs.count {
                    addTask(at: next, in: &group, inputs: inputs, transform: transform)
                    next += 1
                }
            }

            // safer unwrap
            return results.compactMap { $0 }
        }
    }

    @inline(__always)
    private static func addTask<Input: Sendable, Output: Sendable>(
        at index: Int,
        in group: inout ThrowingTaskGroup<(Int, Output), Error>,
        inputs: [Input],
        transform: @Sendable @escaping (Input) async throws -> Output
    ) {
        let input = inputs[index]

        group.addTask {
            try Task.checkCancellation() // 🔥 propagate early cancel
            return (index, try await transform(input))
        }
    }
    @discardableResult
    public static func streamOrdered<Input: Sendable, Output: Sendable>(
        inputs: [Input],
        maxConcurrentTasks: Int = 1,
        transform: @Sendable @escaping (Input) async throws -> Output
    ) -> AsyncThrowingStream<Output, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let results = try await mapOrdered(
                        inputs: inputs,
                        maxConcurrentTasks: maxConcurrentTasks,
                        transform: transform
                    )
                    results.forEach { continuation.yield($0) }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
