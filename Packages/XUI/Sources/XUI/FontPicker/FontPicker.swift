//  FontPicker.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import SwiftUI

public struct FontPicker: View {
    /// Selection binding exposed publicly
    @Binding var selectedFontName: String

    // Environment
    @Environment(\.dismiss) var dismiss
    @Environment(\.isPresented) var isPresented
    @Environment(\.textSize) var textSize

    // Search
    @State private var searchQuery: String = ""
    @State private var debouncedSearchQuery: String = ""

    // Recent fonts
    private let maxRecentFontCount: Int = 5
    private let separator = ","
    @AppStorage("recentFontString") private var recentFontString: String = ""
    private var recentFonts: [String] {
        recentFontString
            .split(separator: separator)
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    // Families
    private let fontFamilies = UIFont.familyNames.sorted()
    private let alphabets: Array = .init("abcdefghijklmnopqrstuvwxyz")

    /// Init
    public init(selection: Binding<String>) {
        _selectedFontName = selection
    }

    public var body: some View {
        List {
            listContent(trimmedQuery: debouncedSearchQuery)
        }
        .environment(\.defaultMinListRowHeight, 48)
        .navigationTitle("Select Font")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchQuery, placement: .navigationBarDrawer(displayMode: .always))
        .onChange(of: searchQuery) { _, newValue in
            debounceSearch(newValue)
        }
        .onChange(of: selectedFontName) { _, newValue in
            updateRecents(with: newValue)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if isPresented {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            debouncedSearchQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}

// MARK: - List Content

private extension FontPicker {
    @ViewBuilder
    func listContent(trimmedQuery: String) -> some View {
        let filteredFamilies = filteredFamilies(from: fontFamilies, query: trimmedQuery)

        if trimmedQuery.isEmpty {
            RecentFontsSectionView(selectedFontName: $selectedFontName, recentFonts: recentFonts)
        }

        SystemFontsSection(
            selectedFontName: $selectedFontName,
            textSize: textSize,
            dismiss: dismiss,
            searchQuery: trimmedQuery
        )

        AlphabetSections(
            families: filteredFamilies,
            alphabets: alphabets,
            textSize: textSize,
            onPick: { fontName in
                selectedFontName = fontName
                dismiss()
            },
            onNavigate: { family, fonts in
                FontNamePicker(
                    selectedFontName: $selectedFontName,
                    familyName: family,
                    fonts: fonts,
                    dismissParent: { dismiss() }
                )
            }
        )
    }
}

// MARK: - Helpers

private extension FontPicker {
    func filteredFamilies(from families: [String], query: String) -> [String] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return families }
        return families.filter { $0.localizedCaseInsensitiveContains(trimmed) }
    }

    func updateRecents(with selection: String?) {
        guard let selected = selection else { return }
        var fonts = recentFonts.filter { $0 != selected }
        fonts.insert(selected, at: 0)
        recentFontString = fonts.prefix(maxRecentFontCount).joined(separator: separator)
    }

    /// Simple debounce using async/await
    func debounceSearch(_ text: String) {
        let current = text
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 250_000_000) // 250ms
            // Only update if the search text hasn't changed during the delay
            if current == searchQuery {
                debouncedSearchQuery = current.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
    }
}

// MARK: - String & UIFont extensions (kept as-is)

public extension String {
    var fontFace: String {
        if let face = uiFont?.fontDescriptor.object(forKey: .face) as? String {
            return face
        }
        return self
    }

    var fontDisplayName: String {
        if let family = fontFamilyName {
            if UIFont.fontNames(forFamilyName: family).count == 1 {
                return family
            }
            return "\(family) \(fontFace)"
        }
        return self
    }

    var uiFont: UIFont? {
        UIFont(name: self, size: 16)
    }

    var font: Font? {
        guard let uiFont else { return nil }
        return .init(uiFont)
    }

    var fontFamilyName: String? {
        let font = UIFont(name: self, size: 16)
        return font?.familyName == UIFont.systemFontFamilyName ? "System Font" : font?.familyName
    }
}

public extension UIFont {
    static var systemFontFamilyName: String {
        let font = UIFont.systemFont(ofSize: 16)
        return font.familyName
    }
}

extension EnvironmentValues {
    @Entry var textSize: CGFloat = UIFont.labelFontSize
}
