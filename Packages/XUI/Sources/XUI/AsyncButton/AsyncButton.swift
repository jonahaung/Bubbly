//
//  AsyncButton.swift
//  CustomComponents
//
//  Created by Valeriy Malishevskyi on 13.05.2025.
//

import SwiftUI

public struct AsyncButton<Label: View>: View {

    private let action: () async throws -> Void
    private let label: () -> Label
    private let role: ButtonRole?
    private let options: AsyncButtonOptions
    
    var executionModifier: AsyncButtonExecutionModifier {
        AsyncButtonExecutionModifier(
            executionID: executionID,
            options: options,
            isDisabled: $isDisabled,
            action: action
        )
    }
    
    @State private var isDisabled = false
    @State private var executionID: UUID?
    
    public init(
        role: ButtonRole? = nil,
        options: AsyncButtonOptions = [],
        action: @escaping () async -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.role = role
        self.options = options
        self.action = action
        self.label = label
    }
    
    public init(
        options: AsyncButtonOptions = [],
        action: @escaping () async throws -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.role = nil
        self.options = options
        self.action = action
        self.label = label
        
    }
    
    public var body: some View {
        Button(role: role, action: performAction, label: label)
            .disabled(isDisabled)
            .modifier(executionModifier)
    }
    
    private func performAction() {
        executionID = UUID()
    }
}
