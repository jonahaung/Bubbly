import Core
import FirebaseAuth
import FirePhoneOTP
import Foundation
import XUI

@MainActor
@Observable
public final class AuthRouter {
	public enum Route: Sendable, Hashable {
		case signIn
		case userInfo(_ user: User)
		case landing
	}

	public var paths = [AuthRouter.Route]()
	private let cancelBag = CancelBag()

	public func route(to route: AuthRouter.Route) {
		paths.append(route)
	}
}

extension AuthRouter {
	public func startObservingAuthStateChanges() {
		cancelBag.cancel()
		NotificationCenter.default.publisher(for: .firePhoneOTPDidLogIn)
			.debounce(for: 0.5, scheduler: RunLoop.main)
			.sink { [weak self] value in
				guard let self else { return }
				if let user = value.object as? User {
					completeLogin(with: user)
				}
			}
			.store(in: cancelBag)
	}

	private func completeLogin(with user: User) {
		GroupStorage.shared.save(user.uid, for: .auth(.currentUserID))
		route(to: .userInfo(user))
	}
}

extension User: @unchecked @retroactive Sendable {}
