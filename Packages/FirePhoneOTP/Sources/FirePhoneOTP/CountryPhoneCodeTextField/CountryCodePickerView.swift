//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

public struct CountryCodePickerView: View {
    public var countryCode: Binding<CountryCode>

    @State private var searchText = ""
    private var displayedCodes: [CountryCode] {
        if searchText.isEmpty {
            CountryCode.allCodes
        } else {
            CountryCode.allCodes.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }

    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        NavigationView {
            List {
                ForEach(displayedCodes) { code in
                    Button {
                        countryCode.wrappedValue = code
                        dismiss()
                    } label: {
                        HStack {
                            Text(code.flag)
                            HStack {
                                Text(code.name)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(code.phoneCode)
                                    .foregroundStyle(code == countryCode.wrappedValue ? Color
                                        .accentColor : .secondary)
                            }
                        }
                    }
                    .buttonStyle(.borderless)
                }
            }
            .navigationTitle("Country Picker")
            .searchable(text: $searchText, prompt: "Search country by name")
        }
    }
}
