import Foundation
import Services
import Database

extension Array where Element == (Int, MsgCellViewModel) {
	func viewModel(of id: String) -> MsgCellViewModel? {
		first(where: { $0.1.id == id })?.1
	}
	func viewModel(of index: Int) -> MsgCellViewModel? {
		first(where: { $0.0 == index })?.1
	}
	func msg(of id: String) -> MsgSnapshot? {
		viewModel(of: id)?.msg
	}
	func index(of id: String) -> Int? {
		firstIndex(where: { $0.1.id == id })
	}
}

