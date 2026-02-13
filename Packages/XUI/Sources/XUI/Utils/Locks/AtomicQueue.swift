import Foundation

@propertyWrapper
public struct AtomicQueue<Value> {
	private let queue = DispatchQueue(label: "com.jonahaung.AtomicQueue")
	private var value: Value

	public init(wrappedValue: Value) {
		value = wrappedValue
	}

	public var wrappedValue: Value {
		get {
			queue.sync { value }
		}
		set {
			queue.sync { value = newValue }
		}
	}
}
