//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import SwiftUI

public struct CountryCodePickerView: View {
    public var countryCode: Binding<CountryCode>

    @State private var searchText = ""
    private var displayedCodes: [CountryCode] {
        if searchText.isEmpty {
            CountryCode.allCodes
        } else {
            CountryCode.allCodes.filter {
                $0.name.localizedStandardContains(searchText)
            }
        }
    }

    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        NavigationStack {
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
                                    .foregroundStyle(.primary)
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
