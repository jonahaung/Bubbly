//  AsyncOrderedStream.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import Foundation

public enum AsyncOrderedStream {
    @discardableResult
    public static func mapOrdered<Input: Sendable, Output: Sendable>(
        inputs: [Input],
        maxConcurrentTasks: Int =
            ProcessInfo.processInfo
                .activeProcessorCount,
        transform: @Sendable @escaping (Input) async throws
            -> Output
    ) async throws
        -> [
            Output
        ]
    {
        try await withThrowingTaskGroup(of: (Int, Output).self) { group in
            var results = [Output?](repeating: nil, count: inputs.count)

            for index in 0 ..< min(maxConcurrentTasks, inputs.count) {
                let input = inputs[index]
                group.addTask {
                    let output = try await transform(input)
                    return (index, output)
                }
            }

            var nextIndex = maxConcurrentTasks

            while let (index, output) = try await group.next() {
                results[index] = output

                if nextIndex < inputs.count {
                    let input = inputs[nextIndex]
                    let currentIndex = nextIndex
                    group.addTask {
                        let output = try await transform(input)
                        return (currentIndex, output)
                    }
                    nextIndex += 1
                }
            }

            return results.map { $0! }
        }
    }

    @inline(__always)
    private static func addTask<Input: Sendable, Output: Sendable>(
        at index: Int,
        in group: inout ThrowingTaskGroup<
            (Int, Output),
            Error
        >,
        inputs: [Input],
        transform: @Sendable @escaping (Input) async throws
            -> Output
    ) {
        group.addTask {
            let output = try await transform(inputs[index])
            return (index, output)
        }
    }
}
