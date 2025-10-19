import Foundation
import Database
import Services
import XUI

enum MsgCellItem: Sendable, Identifiable, Hashable {
	
    case msg(MsgCellViewModel)
    case timeSeparator((msgID: String, date: Date))
    case spacer(msgID: String)
    case msgHeader(viewModel: MsgCellViewModel)
    case msgFooter(viewModel: MsgCellViewModel)

    var id: String {
        switch self {
        case .msg(let vm):
            // Assuming MsgCellViewModel has a stable identifier, e.g., msgID
            return "msg:\(vm.msgID)"
        case .timeSeparator(let tuple):
            let dateString = ISO8601DateFormatter().string(from: tuple.date)
            return "timeSeparator:\(tuple.msgID):\(dateString)"
        case .spacer(let msgID):
            return "spacer:\(msgID)"
        case .msgHeader(let vm):
            return "msgHeader:\(vm.msgID)"
        case .msgFooter(let vm):
            return "msgFooter:\(vm.msgID)"
        }
    }

    // Manual Equatable that uses the same notion of identity and associated values
    static func == (lhs: MsgCellItem, rhs: MsgCellItem) -> Bool {
        switch (lhs, rhs) {
        case (.msg(let l), .msg(let r)):
            return l.msgID == r.msgID
        case (.timeSeparator(let l), .timeSeparator(let r)):
            return l.msgID == r.msgID && l.date == r.date
        case (.spacer(let l), .spacer(let r)):
            return l == r
        case (.msgHeader(let l), .msgHeader(let r)):
            return l.msgID == r.msgID
        case (.msgFooter(let l), .msgFooter(let r)):
            return l.msgID == r.msgID
        default:
            return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .msg(let vm):
            hasher.combine(0)
            hasher.combine(vm.msgID)
        case .timeSeparator(let tuple):
            hasher.combine(1)
            hasher.combine(tuple.msgID)
            hasher.combine(tuple.date)
        case .spacer(let msgID):
            hasher.combine(2)
            hasher.combine(msgID)
        case .msgHeader(let vm):
            hasher.combine(3)
            hasher.combine(vm.msgID)
        case .msgFooter(let vm):
            hasher.combine(4)
            hasher.combine(vm.msgID)
        }
    }
}
