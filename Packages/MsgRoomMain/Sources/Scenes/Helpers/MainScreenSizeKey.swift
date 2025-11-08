//
//  MainWindowSizeKey.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 6/11/25.
//

import SwiftUI

private struct MainScreenSizeKey: EnvironmentKey {
    static let defaultValue: CGSize = .zero
}

public extension EnvironmentValues {
    var screenSize: CGSize {
        get { self[MainScreenSizeKey.self] }
        set { self[MainScreenSizeKey.self] = newValue }
    }
}
