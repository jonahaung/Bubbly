//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Combine
import SwiftUI

struct OTPView: View {
    enum FocusField: Hashable {
        case field
    }

    @FocusState private var focusedField: FocusField?
    @Binding var otpCode: String
    var otpCodeLength: Int

    init(otpCode: Binding<String>, otpCodeLength: Int) {
        _otpCode = otpCode
        self.otpCodeLength = otpCodeLength
    }

    var body: some View {
        VStack {
            HStack(spacing: 2) {
                ForEach(0..<otpCodeLength, id: \.self) { index in
                    ZStack {
                        Image(systemName: "circle")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.secondary)
                        if otpCode.count > index {
                            Image(systemName: "\(getPin(at: index)).circle.fill")
                                .resizable()
                        }
                    }
                    .frame(width: 20, height: 20, alignment: .center)
                }
            }
            .frame(height: 50)
            .background {
                TextField("", text: $otpCode)
                    .frame(width: 0, height: 0, alignment: .center)
                    .font(Font.system(size: 0))
                    .accentColor(.clear)
                    .foregroundColor(.clear)
                    .textContentType(.oneTimeCode)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .onReceive(Just(otpCode)) { _ in limitText(otpCodeLength) }
                    .focused($focusedField, equals: .field)
                    .task {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            focusedField = .field
                        }
                    }
            }
        }
        .fontDesign(.monospaced)
    }

    private func getPin(at index: Int) -> String {
        guard otpCode.count > index else {
            return ""
        }
        return otpCode[index]
    }

    private func limitText(_ upper: Int) {
        if otpCode.count > upper {
            otpCode = String(otpCode.prefix(upper))
        }
    }
}

public extension String {
    subscript(idx: Int) -> String {
        String(self[index(startIndex, offsetBy: idx)])
    }
}

#Preview {
    OTPView(otpCode: .constant("62"), otpCodeLength: 4)
}
