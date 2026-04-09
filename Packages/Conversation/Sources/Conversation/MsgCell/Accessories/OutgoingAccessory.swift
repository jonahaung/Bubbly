// © 2026 Aung Ko Min

import Core
import Database
import Services
import SwiftUI

extension MsgCell {
    struct OutgoingAccessory: View {
        // MARK: Internal

        var body: some View {
            if viewModel.state.isSender, let namespace {
                ZStack(alignment: .bottom) {
                    Group {
                        switch viewModel.state.deliveryStatus {
                        case .delivered:
                            Image(systemName: "checkmark.circle", variableValue: 0.0)
                                .resizable()
                                .scaledToFit()
                                .symbolVariableValueMode(.draw)
                        case .sending:
                            Image(systemName: "progress.indicator")
                                .resizable()
                                .scaledToFit()
                                .symbolEffect(
                                    .rotate,
                                    options: .repeat(.periodic), value: viewModel.state.isVisible,
                                )
                        case .sendingFailed:
                            Image(systemName: "exclamationmark.circle")
                                .resizable()
                                .scaledToFit()
                        default:
                            EmptyView()
                        }
                    }
                    .frame(square: 12)
                    .padding(.bottom, 2)
                    .fontWeight(.bold)
                    .imageScale(.small)
                    .symbolRenderingMode(.palette)
                }
                .frame(width: 12)
                .padding(.trailing, 8)
                .allowsHitTesting(false)
                .matchedGeometryEffect(
                    id: viewModel.id,
                    in: namespace.value,
                    anchor: .leading,
                    isSource: true,
                )
            }
        }

        // MARK: Private

        @Environment(MsgCellViewModel.self) private var viewModel
        @Environment(\.sharedNamespace) private var namespace
    }
}
