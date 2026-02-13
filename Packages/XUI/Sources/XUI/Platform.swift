import Foundation

public enum Platform {
	public static var isSimulator: Bool {
		#if targetEnvironment(simulator)
			return true
		#else
			return false
		#endif
	}
}
