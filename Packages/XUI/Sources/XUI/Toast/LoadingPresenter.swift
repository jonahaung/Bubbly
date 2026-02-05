// LoadingPresenter.swift (in XUI)
import SwiftUI

@MainActor
@Observable
public final class LoadingPresenter {
	public var showLoading: Bool = false

	public func loading(_ value: Bool) {
		guard value != showLoading else { return }
		withTransaction(.withoutAnimation) {
			showLoading = value
		}
	}
	public static let shared: LoadingPresenter = .init()
}
public enum Loading {
	@MainActor public static func show(_ value: Bool) {
		LoadingPresenter.shared.loading(value)
	}
}
