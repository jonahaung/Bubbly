import Foundation

@globalActor
public struct ChatActor {
	public actor ChatActor {}
	public static let shared = ChatActor()
}
