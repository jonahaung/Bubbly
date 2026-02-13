import FirebaseAuth
import Foundation

enum FirePhoneLoginProgressState: Hashable {
	case none, loading
	case loggedIn(User, isNewUser: Bool)
}
