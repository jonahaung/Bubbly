//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Combine
import FirebaseAuth
import Foundation
import PhoneNumberKit

@MainActor
class FirePhoneOTPLoginViewModel: ObservableObject {
    @Published var viewState = FirePhoneLoginViewState.enterPhoneNumber
    @Published var phoneNumber = PhNumber.locale
    @Published var isLoading = false
    @Published var otp = ""
    private var cancellables = Set<AnyCancellable>()
    private var verificationID: String?

    init() {
        $phoneNumber
            .removeDuplicates(by: { one, two in
                one.rawString != two.rawString
            })
            .debounce(for: 1, scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.validatePhoneNumber(value)
            }
            .store(in: &cancellables)

        $otp
            .filter { $0.count == 6 }
            .debounce(for: 1, scheduler: RunLoop.main)
            .sink { [weak self] value in
                Task {
                    await self?.verifyCode(code: value)
                }
            }
            .store(in: &cancellables)
    }
}

extension FirePhoneOTPLoginViewModel {
    func sendCode(phoneNumber: String) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            verificationID = try await PhoneAuthProvider.provider()
                .verifyPhoneNumber(phoneNumber, uiDelegate: nil)
            viewState = .verifyOTP
        } catch {
            viewState = .error(error.localizedDescription)
        }
    }

    func verifyCode(code: String) async {
        guard !isLoading else { return }
        guard let verificationID else {
            viewState = .error("Request a new verification code.")
            return
        }
        isLoading = true
        defer { isLoading = false }
        let credentials = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: code
        )
        do {
            let authResult = try await Auth.auth().signIn(with: credentials)
            viewState = .loggedIn(
                user: authResult.user,
                isNewUser: authResult.additionalUserInfo?.isNewUser == true
            )
        } catch {
            viewState = .error(error.localizedDescription)
        }
    }

    func reset() {
        isLoading = false
        otp = ""
        phoneNumber.rawString = ""
        verificationID = nil
        viewState = .enterPhoneNumber
    }
}

extension FirePhoneOTPLoginViewModel {
    private func validatePhoneNumber(_ phoneNumber: PhNumber) {
        phoneNumber.validate()
        applyPatternOnNumbers(
            &phoneNumber.rawString,
            pattern: "########",
            replacementCharacter: "#"
        )
        if let number = phoneNumber.formattedNumber, !isLoading {
            Task {
                await sendCode(phoneNumber: number)
            }
        }
    }

    func applyPatternOnNumbers(
        _ stringvar: inout String,
        pattern: String,
        replacementCharacter: Character
    ) {
        var pureNumber = stringvar.replacingOccurrences(
            of: "[^0-9]",
            with: "",
            options: .regularExpression
        )
        for index in 0..<pattern.count {
            guard index < pureNumber.count else {
                stringvar = pureNumber
                return
            }
            let stringIndex = String.Index(utf16Offset: index, in: pattern)
            let patternCharacter = pattern[stringIndex]
            guard patternCharacter != replacementCharacter else { continue }
            pureNumber.insert(patternCharacter, at: stringIndex)
        }
        stringvar = pureNumber
    }
}
