import Database
import FirebaseAuth
import Foundation

public enum Launching {
	public enum MainRoute {
		case loading
		case getStarted
		case main(_ user: CurrentUserModel)
	}

	enum DefaultKeys {
		static let getStarted = "AppLauncher.getStarted"
	}
}
