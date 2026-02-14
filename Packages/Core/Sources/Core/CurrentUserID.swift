import FirebaseAuth

public var currentUserId: String? {
	Auth.auth().currentUser?.uid ?? GroupStorage.shared.string(for: .auth(.currentUserID))
}
