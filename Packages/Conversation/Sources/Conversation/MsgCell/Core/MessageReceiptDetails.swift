//  MessageReceiptDetails.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI
import Database
import Services

struct MessageReceiptDetails: View, @MainActor Equatable {
    let state: MsgCellViewModel.State
    @Environment(ChatManager.self) private var manager

    var body: some View {
        if state.isSender, let receipts, !receipts.isEmpty {
            VStack(alignment: .trailing, spacing: 0) {
                ForEach(receipts, id: \.id) { receipt in
                    Text(lineText(for: receipt))
                }
            }
            .font(.system(size: UIFont.smallSystemFontSize - 1, weight: .regular, design: .default))
            .foregroundStyle(Color.tertiaryText)
            .lineLimit(1)
            .allowsHitTesting(false)
        }
    }

    private var receipts: [MsgRecipientReceipt]? {
        state.msg.outgoingStatus?.receipts
            .filter { !$0.userID.hasPrefix("aggregate:") }
            .sorted {
                if $0.date != $1.date {
                    return $0.date > $1.date
                }
                return $0.userID < $1.userID
            }
    }

    private func lineText(for receipt: MsgRecipientReceipt) -> String {
        let name = manager.contactsRepository?.contact(for: receipt.userID)?.name ?? receipt.userID
        return "\(name) \u{2022} \(receipt.status.localizedName)"
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.state.msg.outgoingStatus == rhs.state.msg.outgoingStatus
    }
}
