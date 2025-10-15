//
//  PhoneNumber.swift
//  CountryPhoneCodePicker
//
//  Created by Aung Ko Min on 31/10/22.
//

import Foundation
import PhoneNumberKit

@Observable
public class PhNumber {
    
    public var id: String { countryCode.country + rawString }
    public var countryCode: CountryCode
    public var rawString: String
    public var plceHolder: String {
        phoneNumberKit.getFormattedExampleNumber(forCountry: countryCode.country) ?? "Phone Number"
    }
    private let phoneNumberKit = PhoneNumberKit()
    
    public var isValid: Bool {
        phoneNumberKit.isValidPhoneNumber(rawString)
    }
    
    public var formattedNumber: String? {
        do {
            let phoneNumber = try phoneNumberKit.parse(rawString)
            return phoneNumberKit.format(phoneNumber, toType: .e164)
        } catch {
            do {
                let phoneNumber = try phoneNumberKit.parse(countryCode.phoneCode + rawString)
                return phoneNumberKit.format(phoneNumber, toType: .e164)
            } catch {
                return nil
            }
        }
    }
    
	@MainActor public static let locale = PhNumber(countryCode: .current)
    
    public init(countryCode: CountryCode) {
        self.countryCode = countryCode
        self.rawString = ""
    }
    
    public func validate() {
        guard isValid else {
            return
        }
        do {
            let phoneNumber = try phoneNumberKit.parse(rawString)
            if let regionID = phoneNumber.regionID {
                countryCode = .init(code: regionID)
            }
        } catch {
            print(error)
        }
    }
}
