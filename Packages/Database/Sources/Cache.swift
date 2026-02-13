import Core
import Foundation
import XUI

@MainActor
public struct Cache {
	public static let shared = Cache()
	public let date = ExpiringCache<String>()
	private init() {}
}
