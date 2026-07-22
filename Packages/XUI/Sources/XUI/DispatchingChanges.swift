//
//  DispatchingChanges.swift
//  XUI
//
//  Created by Aung Ko Min on 25/5/26.
//

import SwiftUI

public struct DispatchingChanges<
    ID: Hashable,
    Input: Sendable & Equatable,
    Content: View
>: View {
    
    private let id: ID
    private let input: Input
    private let duration: Duration
    private let content: (Input) -> Content
    
    @State private var dispatchedInput: Input?
    @State private var task: Task<Void, Never>?
    
    public init(
        to input: Input,
        for duration: Duration = .seconds(0.3),
        id: ID,
        @ViewBuilder _ content: @escaping (Input) -> Content
    ) {
        self.id = id
        self.input = input
        self.duration = duration
        self.content = content
    }
    
    public var body: some View {
        content(dispatchedInput ?? input)
            .onChange(of: id) {
                reset()
            }
            .onChange(of: input, initial: true) {
                dispatch(input)
            }
            .onDisappear {
                task?.cancel()
            }
    }
    
    @MainActor
    private func reset() {
        task?.cancel()
        task = nil
        dispatchedInput = nil
    }
    
    @MainActor
    private func dispatch(_ newValue: Input) {
        task?.cancel()
        
        guard dispatchedInput != nil else {
            dispatchedInput = newValue
            return
        }
        
        task = Task { @MainActor in
            try? await Task.sleep(for: duration)
            
            guard !Task.isCancelled else { return }
            
            dispatchedInput = newValue
        }
    }
}
