//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import SwiftUI

struct OTPView: View {
    @FocusState private var focusedField: OTPFocusField?
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
                            Image(systemName: "\(pin(at: index)).circle.fill")
                                .resizable()
                        }
                    }
                    .frame(width: 20, height: 20, alignment: .center)
                }
            }
            .frame(height: 50)
            .accessibilityHidden(true)
            .overlay {
                TextField("Verification code", text: $otpCode)
                    .opacity(0.01)
                    .textContentType(.oneTimeCode)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .field)
                    .accessibilityLabel("Verification code")
                    .onChange(of: otpCode) {
                        limitText(otpCodeLength)
                    }
            }
            .task {
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }
                focusedField = .field
            }
        }
        .fontDesign(.monospaced)
    }

    private func pin(at offset: Int) -> String {
        guard offset < otpCode.count else {
            return ""
        }
        let index = otpCode.index(otpCode.startIndex, offsetBy: offset)
        return String(otpCode[index])
    }

    private func limitText(_ upper: Int) {
        if otpCode.count > upper {
            otpCode = String(otpCode.prefix(upper))
        }
    }
}

#Preview {
    OTPView(otpCode: .constant("62"), otpCodeLength: 4)
}
