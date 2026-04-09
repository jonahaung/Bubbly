//
// Copyright © 2026 Aung Ko Min. All rights reserved.
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
        .font(.title2)
        .padding(3)
        .sheet(isPresented: $showCountryPicker) {
            CountryCodePickerView(countryCode: phoneNumber.countryCode)
        }
    }
}
