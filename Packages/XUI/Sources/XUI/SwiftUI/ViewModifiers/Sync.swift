//
//  Synchronizer.swift
//  HomeForYou
//
//  Created by Aung Ko Min on 24/4/23.
//

import SwiftUI
import Combine

private struct LazySynchronizer<Value: Equatable>: ViewModifier {

    @Binding var original: Value
    @Binding var changed: Value

    func body(content: Content) -> some View {
        content
            .onAppear {
                changed = original
            }
            .onDisappear {
                original = changed
            }
    }
}
private struct DebounceSync<Value: Equatable>: ViewModifier {

    @Binding var original: Value
    @Binding var changed: Value
    let seconds: Double

    private let publisher = PassthroughSubject<Value, Never>()
    private let reversePublisher = PassthroughSubject<Value, Never>()

    func body(content: Content) -> some View {
        content
            .onChange(of: changed) { _, _ in
                publisher.send(changed)
            }
            .onReceive(
                publisher
                    .removeDuplicates()
                    .debounce(for: .seconds(seconds), scheduler: RunLoop.main)
            ) {
                original = $0
            }
            .onChange(of: original) { _, newValue in
                reversePublisher.send(newValue)
            }
            .onReceive(
                reversePublisher
                    .removeDuplicates()
                    .debounce(for: .seconds(seconds), scheduler: RunLoop.main)
            ) {
                changed = $0
            }
    }
}
public extension View {
    func debounceSync<Value: Equatable>(_ original: Binding<Value>, _ changed: Binding<Value>, _ seconds: Double = 0.5) -> some View {
        ModifiedContent(content: self, modifier: DebounceSync(original: original, changed: changed, seconds: seconds))
    }
    func lazySync<Value: Equatable>(_ original: Binding<Value>, _ changed: Binding<Value>) -> some View {
        ModifiedContent(content: self, modifier: LazySynchronizer(original: original, changed: changed))
    }
}
