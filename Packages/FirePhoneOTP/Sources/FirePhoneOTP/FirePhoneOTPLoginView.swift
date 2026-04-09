//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import PhoneNumberKit
import SwiftUI

public struct FirePhoneOTPLoginView: View {
    @StateObject private var viewModel = FirePhoneOTPLoginViewModel()
    @FocusState private var focused: FirePhoneLoginViewState?
    public init() {}

    public var body: some View {
        VStack(alignment: .center) {
            switch viewModel.viewState {
            case .enterPhoneNumber:
                PhoneNumberTextField(phoneNumber: $viewModel.phoneNumber)
                    .frame(height: 60)
                    .padding(.horizontal)
                    .focused($focused, equals: .enterPhoneNumber)
                    .onAppear {
                        if viewModel.phoneNumber.rawString.isEmpty {
                            focused = .enterPhoneNumber
                        }
                    }
                Divider()
            case .verifyOTP:
                OTPView(otpCode: $viewModel.otp, otpCodeLength: 6)
                    .padding()
            case .error:
                Button {
                    focused = .enterPhoneNumber
                    viewModel.reset()
                } label: {
                    Text("Reset")
                }
            case .loggedIn(let user, isNewUser: _):
                ProgressView().controlSize(.mini)
                    .task {
                        NotificationCenter.default.post(name: .firePhoneOTPDidLogIn, object: user)
                    }
            }
            Text(viewModel.viewState.subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding()
            Spacer()
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                focused = nil
                            }
                        }
                }
            }
        }
        .navigationTitle(viewModel.viewState.title)
        .navigationBarBackButtonHidden()
    }
}
