import Foundation

@globalActor
public struct SomeActor {
	public actor SomeActor {}
	public static let shared = SomeActor()
}
