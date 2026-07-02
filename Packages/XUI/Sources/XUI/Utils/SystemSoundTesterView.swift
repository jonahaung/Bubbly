//  SystemSoundTesterView.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

public struct SystemSoundTesterView: View {
    @StateObject private var registry: SystemSoundRegistry = .init()
    @State private var query = ""

    public init() {}

    public var body: some View {
        List {
            ForEach(filteredItems) { item in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(item.name)
                            .font(.headline)
                        Spacer()
                        Button("Play") {
                            SystemSoundPlayer.play(item)
                        }
                        .buttonStyle(.bordered)
                    }
                    Text("#\(item.id)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Name", text: nameBinding(for: item.id))
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                }
                .padding(.vertical, 4)
            }
        }
        .searchable(text: $query)
        .toolbar {
            Button("Reset Names") {
                registry.resetNames()
            }
        }
    }

    private var filteredItems: [SystemSoundItem] {
        if query.isEmpty {
            return registry.items
        }
        return registry.items.filter { item in
            item.name.localizedCaseInsensitiveContains(query) || String(item.id).contains(query)
        }
    }

    private func nameBinding(for id: UInt32) -> Binding<String> {
        .init(
            get: { registry.name(for: id) },
            set: { registry.rename(id: id, name: $0) }
        )
    }
}
