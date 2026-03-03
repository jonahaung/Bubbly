//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

public struct XNavPickerBar<T: XPickable>: View {
    private let title: String
    private let items: [T]
    @Binding private var selection: T

    public init(_ title: String = "Picker", _ items: [T], _ selection: Binding<T>) {
        self.title = title
        self.items = items
        _selection = selection
    }

    public var body: some View {
        NavigationLink {
            XPickerView(
                title: title,
                items: items,
                selection: $selection
            )
        } label: {
            LabeledContent(title) {
                Text(.init(selection.title))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

public struct XPickerView<T: XPickable>: View {
    let title: String
    let items: [T]
    @Binding var selection: T
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    @State private var isPresented = false

    private var currentItems: [T] {
        if searchText.isEmpty {
            return items
        }
        let needle = searchText.lowercased()
        return items.filter { $0.title.lowercased().contains(needle) }
    }

    public init(
        title: String,
        items: [T],
        selection: Binding<T>
    ) {
        self.title = title
        self.items = items
        _selection = selection
    }

    public var body: some View {
        ScrollViewReader { proxy in
            Form {
                Section {
                    ForEach(currentItems) { item in
                        PickerRow(
                            item: item,
                            isSelected: item.title == selection.title,
                            badge: item.badge
                        ) {
                            update(item)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                dismiss()
                            }
                        }
                        .id(item.id)
                    }
                    if currentItems.isEmpty {
                        ContentUnavailableView.search
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    AsyncButton {
                        await MainActor.run {
                            isPresented = true
                        }
                    } label: {
                        SystemImage(.magnifyingglass)
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.smooth(duration: 0.5)) {
                        proxy.scrollTo(selection.id)
                    }
                }
            }
            .navigationBarTitle(title)
            .navigationSubtitle("Pick one from the list")
            .toolbarTitleDisplayMode(.inlineLarge)
            .searchable(
                text: $searchText,
                isPresented: $isPresented,
                placement: .automatic,
                prompt: "Search \(title)"
            )
            .sensoryFeedback(.selection, trigger: selection)
        }
    }

    private func update(_ item: T) {
        if selection.title == item.title {
            selection = T.empty
            return
        }
        selection = item
    }
}

private struct PickerRow<T: XPickable>: View {
    let item: T
    let isSelected: Bool
    let badge: RenderNode?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Badge (if any) – keep concrete type by always returning some View
                if let badge {
                    badge.eraseToNode()
                }

                Text(item.title)

                Spacer(minLength: 8)

                SystemImage(isSelected ? .checkmarkCircleFill : .circle)
                    .contentTransition(.symbolEffect(.replace))
                    .foregroundStyle(isSelected ? Color
                        .accentColor : Color(uiColor: .quaternaryLabel))
            }
        }
    }
}
