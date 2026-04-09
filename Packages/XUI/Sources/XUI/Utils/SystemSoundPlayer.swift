//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import AudioToolbox
import SwiftUI

public struct SystemSoundItem: Identifiable, Hashable, Sendable {
    public let id: UInt32
    public var name: String

    public init(id: UInt32, name: String) {
        self.id = id
        self.name = name
    }
}

public enum SystemSoundCatalog {
    public static let defaultItems: [SystemSoundItem] = [
        .init(id: 100, name: "System 100"),
        .init(id: 1002, name: "Voicemail"),
        .init(id: 1004, name: "Message Sent"),
        .init(id: 1007, name: "Message Received 1"),
        .init(id: 1009, name: "Message Received 3"),
        .init(id: 1013, name: "Message Received 7"),
        .init(id: 1016, name: "Message Received 10"),
        .init(id: 1018, name: "Message Received 12"),
        .init(id: 1022, name: "Message Received 16"),
        .init(id: 1052, name: "Recording Begin"),
        .init(id: 1053, name: "Recording End"),
        .init(id: 1054, name: "Call Drop"),
        .init(id: 1055, name: "Call Connect"),
        .init(id: 1057, name: "Call Waiting"),
        .init(id: 1058, name: "Call Waiting 2"),
        .init(id: 1104, name: "Tock"),
        .init(id: 1157, name: "Tink")
    ]
}

public enum SystemSoundPlayer {
    public static func play(_ id: UInt32) {
        AudioServicesPlaySystemSound(id)
    }

    public static func play(_ item: SystemSoundItem) {
        AudioServicesPlaySystemSound(item.id)
    }
}

@MainActor
public final class SystemSoundRegistry: ObservableObject {
    @Published public private(set) var items: [SystemSoundItem]
    private let storageKey = "xui.systemsounds.names"

    public init(items: [SystemSoundItem] = SystemSoundCatalog.defaultItems) {
        self.items = Self.applyStoredNames(to: items)
    }

    public func name(for id: UInt32) -> String {
        items.first(where: { $0.id == id })?.name ?? "Sound \(id)"
    }

    public func rename(id: UInt32, name: String) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].name = name
        storeNames()
    }

    public func resetNames() {
        items = SystemSoundCatalog.defaultItems
        storeNames()
    }

    private func storeNames() {
        let map = items.reduce(into: [String: String]()) { result, item in
            result[String(item.id)] = item.name
        }
        UserDefaults.standard.set(map, forKey: storageKey)
    }

    private static func applyStoredNames(to items: [SystemSoundItem]) -> [SystemSoundItem] {
        guard let stored = UserDefaults.standard
            .dictionary(forKey: "xui.systemsounds.names") as? [String: String]
        else {
            return items
        }
        return items.map { item in
            if let name = stored[String(item.id)] {
                return .init(id: item.id, name: name)
            }
            return item
        }
    }
}
