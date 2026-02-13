public final class ElementOrganizer<Element> {
	public struct Index {
		public let index: Int
		public let isLast: Bool
		public let element: Element?

		public init(index: Int, isLast: Bool, element: Element?) {
			self.index = index
			self.isLast = isLast
			self.element = element
		}
	}

	public enum NextElement {
		case none
		case next(Element)
		case ended
	}

	public enum ElementOrganizerError: Error {
		case noneLastElement
	}

	private var buffer: [Int: [Element]] = [:]
	private var finished: Set<Int> = []
	private var current: Int = 0

	public init() {}

	public func insert(_ index: Index) {
		let element = index.element
		let isLast = index.isLast
		let index = index.index

		if let element {
			addToBuffer(element, at: index)
		}
		if isLast {
			finished.insert(index)
		}
	}

	public func next() -> NextElement {
		if var elements = buffer[current], !elements.isEmpty {
			let element = elements.removeFirst()
			buffer[current] = elements

			return .next(element)
		} else if finished.contains(current) {
			buffer.removeValue(forKey: current)
			finished.remove(current)
			current += 1

			return .none
		} else if !buffer.isEmpty || !finished.isEmpty {
			return .none
		} else {
			return .ended
		}
	}

	private func addToBuffer(_ element: Element, at index: Int) {
		var elements = buffer[index] ?? []
		elements.append(element)
		buffer[index] = elements
	}
}
