//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SFSafeSymbols
import SwiftUI
import XUI
import Pow

struct ChatAccessoryBar: View {
    @Environment(ChatViewManager.self) private var manager
    @Namespace private var chatNoticeView
	@State private var buttonPressed = false

    var body: some View {
        HStack(alignment: .bottom) {
			Spacer()
            if let accessory = manager.presentation.state.bottomAccessory {
                if accessory == .scrollDownButton {

					Image(systemName: "chevron.down")
						.resizable()
						.scaledToFit()
						.padding(12)
						.frame(square: 40)
						.background(.windowBackground, in: .circle)
						.changeEffect(
							.pulse(
								shape: .circle,
								style: .yellow,
								drawingMode: .stroke
							),
							value: buttonPressed
						)
						._onButtonGesture {_ in
							buttonPressed.toggle()
						} perform: {
							manager.handleScrollDownButtonTap()
						}
                }
            }
        }
        .frame(height: 40)
        .padding(.horizontal, 16)
        .geometryGroup()
    }
}
