//
//  XNavPickerBar.swift
//  Device Monitor
//
//  Created by Aung Ko Min on 21/9/22.
//

import SwiftUI

public struct XNavPickerBar<Item: XPickable>: View {
    private let title: String
    private let items: [Item]
    @Binding private var selection: Item

    public init(_ title: String = "Picker", _ items: [Item], _ selection: Binding<Item>) {
        self.title = title
        self.items = items
        _selection = selection
    }

    public var body: some View {
        HStack {
            Text(.init(title))
            Spacer()
            Text(.init(selection.title))
                .foregroundStyle(.secondary)
        }
        ._tapToPush {
            XPickerView(
                title: title,
                items: items,
                selection: $selection
            )
        }
        .buttonStyle(.plain)
    }
}

private struct XPickerView<Item: XPickable>: View {
    let title: String
    let items: [Item]
    @Binding var selection: Item
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    @State private var isPresented = false
    private var currentItems: [Item] {
        searchText.isEmpty ? items : items.filter { $0.title.lowercased().contains(searchText.lowercased()) }
    }

    @State private var scrollPosition = ScrollPosition(idType: String.self)

    var body: some View {
        Form {
            Section {
                ForEach(currentItems) { item in
                    HStack(spacing: 20) {
                        let isSelected = item.title == selection.title
                        SystemImage(
                            isSelected ? .checkmarkCircleFill : .circle,
                            20
                        )
                        .foregroundStyle(
                            isSelected ? Color.accentColor : .quaternaryLabel
                        )
                        AsyncButton {
                            update(item)
                            try await Task.sleep(for: .seconds(0.15))
                            dismiss()
                        } label: {
                            HStack {
                                Text(item.title)
                                    .foregroundColor(.primary)
                                Spacer()
                                if item.color != .accentColor {
                                    Circle()
                                        .fill(item.color)
                                        .frame(width: 20, height: 20)
                                }
                            }
                        }
                        .buttonStyle(.borderless)
                    }
                    .id(item.title)
                }
                if currentItems.isEmpty {
                    ContentUnavailableView.search
                }
            }
        }
        .scrollPosition($scrollPosition, anchor: .center)
        .onAppear {
            scrollPosition.scrollTo(id: selection.title, anchor: .center)
        }
        .navigationBarTitle(title)
        .navigationBarItems(trailing: trailingItem)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $searchText,
            isPresented: $isPresented,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: "Search \(title)"
        )
    }

    private var trailingItem: some View {
        AsyncButton {
            await MainActor.run {
                isPresented = true
            }
        } label: {
            SystemImage(.magnifyingglass)
        }
    }

    private func scrollToSelectedItem(_ scrollView: ScrollViewProxy) {
        if !selection.isEmpty {
            withAnimation {
                scrollView.scrollTo(selection.title, anchor: .center)
            }
        }
    }

    private func update(_ item: Item) {
        if selection.title == item.title {
            selection = Item.empty
            return
        }
        selection = item
    }
}
