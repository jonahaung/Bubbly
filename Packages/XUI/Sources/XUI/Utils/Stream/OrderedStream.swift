//import Foundation
//
//public struct OrderedStream<Element> {
//	internal var base: AnySequence<Element>
//
//	internal init<S: Sequence>(_ base: S) where S.Element == Element {
//		self.base = AnySequence<Element>(base)
//	}
//
//	internal init(_ base: AnySequence<Element>) {
//		self.base = base
//	}
//}
//
//extension OrderedStream: LazySequenceProtocol {
//	public typealias Element = Element
//	public typealias Iterator = AnySequence<Element>.Iterator
//
//	public func makeIterator() -> Self.Iterator {
//		return base.makeIterator()
//	}
//}
//
//internal extension OrderedStream {
//	func apply<B>(
//		maxTasks: Int = cpuCount,
//		queueMax: Int? = nil,
//		dispatch: DispatchQueue? = nil,
//		transform: @escaping (ConcurrentQueue<Index<B>?>, Int, Element) throws -> Void
//	) -> OrderedStream<B> {
//		let sequence = AnySequence<B> { () -> AnyIterator<B> in
//			var first = true
//			var queueOpen = true
//			let queue = ConcurrentQueue<Index<B>?>()
//			let organizer = ElementOrganizer<B>()
//
//			return AnyIterator<B> { () -> B? in
//				if first {
//					first = false
//					let dispatch = dispatch ?? DISPATCH
//					let semaphore = DispatchSemaphore(value: maxTasks)
//
//					dispatch.async {
//						let group = DispatchGroup()
//
//						for (index, elem) in self.enumerated() {
//							group.enter()
//							semaphore.wait()
//
//							dispatch.async {
//								do {
//									try transform(queue, index, elem)
//								} catch {
//									print("Error in OrderedStream.apply: \(error)")
//								}
//
//								group.leave()
//								semaphore.signal()
//							}
//						}
//						group.wait()
//						try? queue.put(nil)
//					}
//				}
//
//				while true {
//					if queueOpen, let element = try? queue.get() {
//						organizer.insert(element)
//					} else {
//						queueOpen = false
//					}
//
//					let next = organizer.next()
//					switch next {
//					case let .next(nextElement):
//						return nextElement
//					case .none:
//						continue
//					case .ended:
//						return nil
//					}
//				}
//			}
//		}
//
//		return OrderedStream<B>(sequence)
//	}
//
//	func map<B>(
//		maxTasks: Int = cpuCount,
//		queueMax: Int? = nil,
//		dispatch: DispatchQueue? = nil,
//		transform: @escaping (Element) throws -> B
//	) -> OrderedStream<B> {
//		apply(
//			maxTasks: maxTasks,
//			queueMax: queueMax,
//			dispatch: dispatch
//		) { queue, index, elem in
//			do {
//				let result = try transform(elem)
//				try queue.put(Index(
//					index: index,
//					isLast: true,
//					element: result
//				))
//			} catch {
//				print("Error in OrderedStream.map: \(error)")
//				try? queue.put(Index(
//					index: index,
//					isLast: true,
//					element: nil
//				))
//			}
//		}
//	}
//
//	func flatMap<B, S: Sequence>(
//		maxTasks: Int = cpuCount,
//		queueMax: Int? = nil,
//		dispatch: DispatchQueue? = nil,
//		transform: @escaping (Element) throws -> S
//	) -> OrderedStream<B> where S.Element == B {
//		apply(
//			maxTasks: maxTasks,
//			queueMax: queueMax,
//			dispatch: dispatch
//		) { queue, index, elem in
//			do {
//				let results = try transform(elem)
//				for resultElem in results {
//					try queue.put(Index(
//						index: index,
//						isLast: false,
//						element: resultElem
//					))
//				}
//			} catch {
//				print("Error in OrderedStream.flatMap: \(error)")
//			}
//
//			try? queue.put(Index(
//				index: index,
//				isLast: true,
//				element: nil
//			))
//		}
//	}
//
//	func filter(
//		maxTasks: Int = cpuCount,
//		queueMax: Int? = nil,
//		dispatch: DispatchQueue? = nil,
//		predicate: @escaping (Element) throws -> Bool
//	) -> OrderedStream<Element> {
//		apply(maxTasks: maxTasks, queueMax: queueMax, dispatch: dispatch) {
//			queue, index, elem in
//			do {
//				if try predicate(elem) {
//					try queue.put(Index(
//						index: index,
//						isLast: true,
//						element: elem
//					))
//				} else {
//					try queue.put(Index(
//						index: index,
//						isLast: true,
//						element: nil
//					))
//				}
//			} catch {
//				print("Error in OrderedStream.filter: \(error)")
//				try? queue.put(Index(
//					index: index,
//					isLast: true,
//					element: nil
//				))
//			}
//		}
//	}
//
//	func forEach(
//		maxTasks: Int = cpuCount,
//		queueMax: Int? = nil,
//		dispatch: DispatchQueue? = nil,
//		action: @escaping (Element) throws -> Void
//	) {
//		apply(
//			maxTasks: maxTasks,
//			queueMax: queueMax,
//			dispatch: dispatch
//		) { _, _, elem in
//			do {
//				try action(elem)
//			} catch {
//				print("Error in OrderedStream.forEach: \(error)")
//			}
//		}
//		.makeIterator()
//		.forEach {}
//	}
//}
//
//public extension Stream {
//	var orderStream: OrderedStream<Element> {
//		OrderedStream(base)
//	}
//}
