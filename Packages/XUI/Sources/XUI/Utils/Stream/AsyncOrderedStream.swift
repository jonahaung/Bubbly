//
//  AsyncOrderedStream.swift
//  XUI
//
//  Created by Aung Ko Min on 14/7/25.
//

import Foundation

public enum AsyncOrderedStream {
	@discardableResult
	public static func mapOrdered<Input: Sendable, Output: Sendable>(inputs: [Input],
	                                                                 maxConcurrentTasks: Int =
	                                                                 	ProcessInfo.processInfo
	                                                                 		.activeProcessorCount,
	                                                                 transform: @Sendable @escaping (Input) async throws
	                                                                 	-> Output) async throws
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

	public static func mapOrdered2<Input: Sendable, Output: Sendable>(inputs: [Input],
	                                                                  maxConcurrentTasks: Int =
	                                                                  	ProcessInfo.processInfo
	                                                                  		.activeProcessorCount,
	                                                                  transform: @Sendable @escaping (Input) async throws
	                                                                  	-> Output) async throws
		-> [
			Output
		]
	{
		guard !inputs.isEmpty else { return [] }

		return try await withThrowingTaskGroup(of: (Int, Output).self) { group in
			var results = ContiguousArray<Output?>(repeating: nil, count: inputs.count)
			let lock = NSLock()

			// Start initial batch of tasks
			for index in inputs.indices.prefix(maxConcurrentTasks) {
				addTask(at: index, in: &group, inputs: inputs, transform: transform)
			}

			// Process results as they complete
			var nextIndex = maxConcurrentTasks
			while let (index, output) = try await group.next() {
				lock.withLock {
					results[index] = output
				}

				if nextIndex < inputs.count {
					addTask(at: nextIndex, in: &group, inputs: inputs, transform: transform)
					nextIndex += 1
				}
			}

			// Verify all results are present before force unwrapping
			assert(results.allSatisfy { $0 != nil }, "All results should be filled")
			return results.map { $0! }
		}
	}

	@inline(__always)
	private static func addTask<Input: Sendable, Output: Sendable>(at index: Int,
	                                                               in group: inout ThrowingTaskGroup<
	                                                               	(Int, Output),
	                                                               	Error
	                                                               >,
	                                                               inputs: [Input],
	                                                               transform: @Sendable @escaping (Input) async throws
	                                                               	-> Output)
	{
		group.addTask {
			let output = try await transform(inputs[index])
			return (index, output)
		}
	}
}
