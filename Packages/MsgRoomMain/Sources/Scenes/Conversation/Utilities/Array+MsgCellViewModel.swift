import Foundation
import Services
import Database

@MainActor
extension Array where Element == MsgCellViewModel {

	func viewModel(of id: String) -> MsgCellViewModel? {
		self.first(where: { $0.id == id })
	}
	func viewModel(of index: Int) -> MsgCellViewModel? {
		self[safe: index]
	}
	func msg(of id: String) -> Message? {
		viewModel(of: id)?.msg
	}
	func index(of id: String) -> Int? {
		firstIndex(where: { $0.id == id })
	}
}
