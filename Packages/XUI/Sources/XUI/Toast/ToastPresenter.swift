//  ToastPresenter.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import SwiftUI

@MainActor
@Observable
public final class ToastPresenter {
    
    public var toast: Toast?
    public static let shared: ToastPresenter = .init()

    @ObservationIgnored
    private var queue: Deque<Toast> = .init()
    
    public func show(_ value: Toast?) {
        guard let value else {
            toast = nil
            return
        }
        queue.enqueue(value)
        processQueue()
    }
}

private extension ToastPresenter {
    func processQueue() {
        guard toast == nil, let next = queue.dequeue() else { return }
        withTransaction(\.disablesAnimations, true) {
            toast = next
        }
    }
}

extension ToastPresenter {
    @MainActor
    public static func show(_ text: String) {
        let node = Text(.init(text)).opaqueView()
        let toast = Toast(node: node, style: .alert)
        shared.show(toast)
    }
}
extension ToastPresenter {
    public static func show(_ value: Toast?) {
        shared.show(value)
    }
}
