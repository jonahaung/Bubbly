// © 2026 Aung Ko Min
import Core
import Database
import Services
import SwiftUI
extension MsgCell {
    struct OutgoingAccessory: View {
        let state: MsgCellViewModel.State
        var body: some View {
            if state.isSender, let namespace {
                ZStack(alignment: .bottom) {
                    Group {
                        switch state.deliveryStatus {
                        case .delivered:
                            Image(systemName: "checkmark.circle", variableValue: 0.0).resizable()
                                .scaledToFit().symbolVariableValueMode(.draw)
                        case .sending:
                            Image(systemName: "progress.indicator").resizable().scaledToFit()
                                .symbolEffect(
                                    .rotate, options: .repeat(.periodic), value: state.isVisible, )
                        case .sendingFailed:
                            Image(systemName: "exclamationmark.circle").resizable().scaledToFit()
                        default: EmptyView()
                        }
                    }.frame(square: 12).padding(.bottom, 2).fontWeight(.bold).imageScale(.small)
                        .symbolRenderingMode(.palette)
                }.frame(width: 12).allowsHitTesting(false).matchedGeometryEffect(
                    id: state.id, in: namespace.value, anchor: .leading, isSource: true,
                ).geometryGroup().equatable(by: state.deliveryStatus)
            }
        }
        @Environment(\.sharedNamespace) private var namespace
    }
}
