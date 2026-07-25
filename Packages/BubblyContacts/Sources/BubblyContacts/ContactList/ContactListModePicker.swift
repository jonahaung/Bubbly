//  ContactListModePicker.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

struct ContactListModePicker: View {
    @Binding var selection: ContactListDisplayMode

    var body: some View {
        Picker("Contact Display", selection: $selection) {
            ForEach(ContactListDisplayMode.allCases) { mode in
                Text(mode.rawValue)
            }
        }
        .pickerStyle(.segmented)
    }
}
