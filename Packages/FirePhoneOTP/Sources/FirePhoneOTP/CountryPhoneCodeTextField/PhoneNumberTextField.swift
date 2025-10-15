//
//  PhoneNumberTextField.swift
//  CountryPhoneCodePicker
//
//  Created by Aung Ko Min on 31/10/22.
//

import SwiftUI

public struct PhoneNumberTextField: View {
    
    private var phoneNumber: Binding<PhNumber>
    @State private var showCountryPicker = false
    
    public init(phoneNumber: Binding<PhNumber>) {
        self.phoneNumber = phoneNumber
    }
    public var body: some View {
        HStack {
            Button {
                phoneNumber.wrappedValue.rawString = ""
                showCountryPicker = true
            } label: {
                Text(phoneNumber.wrappedValue.countryCode.country)
            }
            Divider()
            TextField(phoneNumber.wrappedValue.plceHolder, text: phoneNumber.rawString)
                .textContentType(.telephoneNumber)
                .keyboardType(.phonePad)
            Button {
                phoneNumber.wrappedValue.rawString = ""
                showCountryPicker = true
            } label: {
                Text(phoneNumber.wrappedValue.countryCode.flag)
            }.buttonStyle(.plain)
        }
        .padding(3)
        .sheet(isPresented: $showCountryPicker) {
            CountryCodePickerView(countryCode: phoneNumber.countryCode)
        }
    }
}
