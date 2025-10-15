import Foundation

public struct Stream<Element>: @unchecked Sendable {
	// @usableFromInline
	internal var base: AnySequence<Element>

	/// Creates a sequence that has the same elements as `base`, but on
	/// which some operations such as `map` and `filter` are implemented
	/// lazily.
	// @inlinable // lazy-performance
	internal init<S: Sequence>(_ base: S) where S.Element == Element {
		self.base = AnySequence<Element>(base)
	}

	internal init(_ base: AnySequence<Element>) {
		self.base = base
	}
}

extension Stream: LazySequenceProtocol {
	public typealias Element = Element
	public typealias Iterator = AnySequence<Element>.Iterator

	public func makeIterator() -> Self.Iterator {
		return base.makeIterator()
	}
}

internal extension Stream {
	func apply<B>(
		maxTasks: Int = cpuCount,
		queueMax: Int? = nil,
		dispatch: DispatchQueue? = nil,
		transform: @escaping (ConcurrentQueue<B?>, Element) throws -> Void
	) -> Stream<B> {
		let sequence = AnySequence<B> { () -> AnyIterator<B> in
			var first = true
			let queue = ConcurrentQueue<B?>()

			return AnyIterator<B> { () -> B? in
				if first {
					first = false
					let dispatch = dispatch ?? DISPATCH
					let semaphore = DispatchSemaphore(value: maxTasks)

					dispatch.async {
						let group = DispatchGroup()

						for elem in self {
							group.enter()
							semaphore.wait()

							dispatch.async {
								do {
									try transform(queue, elem)
								} catch {
									print("Error in Stream.apply: \(error)")
								}

								group.leave()
								semaphore.signal()
							}
						}
						group.wait()
						try? queue.put(nil)
					}
				}

				return try? queue.get()
			}
		}

		return Stream<B>(sequence)
	}

	func map<B>(
		maxTasks: Int = cpuCount,
		queueMax: Int? = nil,
		dispatch: DispatchQueue? = nil,
		transform: @escaping (Element) throws -> B
	) -> Stream<B> {
		apply(
			maxTasks: maxTasks,
			queueMax: queueMax,
			dispatch: dispatch
		) { queue, elem in
			do {
				try queue.put(try transform(elem))
			} catch {
				print("Error in Stream.map: \(error)")
			}
		}
	}

	func flatMap<B, S: Sequence>(
		maxTasks: Int = cpuCount,
		queueMax: Int? = nil,
		dispatch: DispatchQueue? = nil,
		transform: @escaping (Element) throws -> S
	) -> Stream<B> where S.Element == B {
		apply(
			maxTasks: maxTasks,
			queueMax: queueMax,
			dispatch: dispatch
		) { queue, elem in
			do {
				for elemResult in try transform(elem) {
					try queue.put(elemResult)
				}
			} catch {
				print("Error in Stream.flatMap: \(error)")
			}
		}
	}

	func filter(
		maxTasks: Int = cpuCount,
		queueMax: Int? = nil,
		dispatch: DispatchQueue? = nil,
		predicate: @escaping (Element) throws -> Bool
	) -> Stream<Element> {
		apply(maxTasks: maxTasks, queueMax: queueMax, dispatch: dispatch) { queue, elem in
			do {
				if try predicate(elem) {
					try queue.put(elem)
				}
			} catch {
				print("Error in Stream.filter: \(error)")
			}
		}
	}

	func forEach(
		maxTasks: Int = cpuCount,
		queueMax: Int? = nil,
		dispatch: DispatchQueue? = nil,
		action: @escaping (Element) throws -> Void
	) {
		apply(
			maxTasks: maxTasks,
			queueMax: queueMax,
			dispatch: dispatch
		) { _, elem in
			do {
				try action(elem)
			} catch {
				print("Error in Stream.forEach: \(error)")
			}
		}
		.makeIterator()
		.forEach {}
	}
}

public extension Sequence {
	var stream: Stream<Element> {
		Stream(self)
	}
}

public extension Stream {
	var stream: Stream {
		self
	}
}
