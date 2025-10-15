//
//  FirePhoneLoginViewModel.swift
//  FirebasePhoneLogin
//
//  Created by Aung Ko Min on 21/4/24.
//

import Foundation
import FirebaseAuth
import PhoneNumberKit
import Combine

@MainActor
class FirePhoneOTPLoginViewModel: ObservableObject {
    
    @Published var viewState = FirePhoneLoginViewState.enterPhoneNumber
    @Published var phoneNumber = PhNumber.locale
    @Published var isLoading = false
    @Published var otp = ""
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        $phoneNumber
            .removeDuplicates(by: { one, two in
                one.rawString != two.rawString
            })
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.validatePhoneNumber(value)
            }
            .store(in: &cancellables)
        
        $otp
            .filter { $0.count == 6}
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.verifyCode(code: value)
            }
            .store(in: &cancellables)
    }
}

extension FirePhoneOTPLoginViewModel {
    
    func sendCode(phoneNumber: String) {
        guard !isLoading else { return }
        isLoading = true
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { [weak self] (verificationId, error) in
            guard let self else { return }
			DispatchQueue.main.async {
                self.isLoading = false
                if let error {
                    self.viewState = .error(error.localizedDescription)
                    return
                }
                UserDefaults.standard.set(verificationId, forKey: "verificationId")
                self.viewState = .verifyOTP
            }
        }
    }
    
    func verifyCode(code: String) {
        guard !isLoading else { return }
        isLoading = true
        let verificationId = UserDefaults.standard.string(forKey: "verificationId") ?? ""
        let credentials = PhoneAuthProvider.provider().credential(withVerificationID: verificationId, verificationCode: code)
        
        Auth.auth().signIn(with: credentials) { [weak self] (authResult, error) in
            guard let self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                if let error {
                    self.viewState = .error(error.localizedDescription)
                    return
                }
                guard let authResult else {
                    self.viewState =  .error("Unknown Error")
                    return
                }
                let user = authResult.user
                self.viewState = .loggedIn(user: user, isNewUser: authResult.additionalUserInfo?.isNewUser ==  true)
            }
        }
    }
    func reset() {
        isLoading = false
        otp = ""
        phoneNumber.rawString = ""
        viewState = .enterPhoneNumber
    }
}
extension FirePhoneOTPLoginViewModel {
    private func validatePhoneNumber(_ phoneNumber: PhNumber) {
        phoneNumber.validate()
        applyPatternOnNumbers(&phoneNumber.rawString, pattern: "########", replacementCharacter: "#")
        if let number = phoneNumber.formattedNumber, !isLoading {
            sendCode(phoneNumber: number)
        }
    }
    
    func applyPatternOnNumbers(_ stringvar: inout String, pattern: String, replacementCharacter: Character) {
        var pureNumber = stringvar.replacingOccurrences( of: "[^0-9]", with: "", options: .regularExpression)
        for index in 0 ..< pattern.count {
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
