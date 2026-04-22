//  SystemFontsSection.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import SwiftUI

struct SystemFontsSection: View {
    @Binding var selectedFontName: String
    let textSize: CGFloat
    let dismiss: DismissAction
    let searchQuery: String

    var body: some View {
        let systemFamilyName = UIFont.systemFontFamilyName
        let systemFontNames = UIFont.fontNames(forFamilyName: systemFamilyName)
        let systemFamilyTitle = "System Font (Default)"

        if searchQuery.isEmpty || systemFamilyTitle.localizedCaseInsensitiveContains(searchQuery) {
            Section(header: Text("System")) {
                NavigationLink {
                    FontNamePicker(
                        selectedFontName: $selectedFontName,
                        familyName: systemFamilyName,
                        fonts: systemFontNames,
                        dismissParent: { dismiss() }
                    )
                } label: {
                    Text(systemFamilyTitle)
                }
                .foregroundStyle(.black)
                .font(.system(size: textSize))
            }
        }
    }
}
