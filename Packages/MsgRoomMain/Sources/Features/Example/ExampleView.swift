// © 2026 Aung Ko Min

import Core
import SwiftUI
import XUI

struct ExampleView: View {

    @State private var viewModel: ExampleViewModel = .init()

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.md) {
                if viewModel.state.isLoading {
                    ProgressView()
                }

                if let error = viewModel.state.error {
                    Text(error)
                        .foregroundStyle(.red)
                }

                if let items = viewModel.state.items {
                    Section {
                        ForEach(items, id: \.self) { item in
                            VStack {
                                HStack(spacing: Spacing.md) {
                                    Text(item)

                                    Spacer()
                                }
                            }
                            .padding(Padding.md)
                            .flexible(.horizontal)
                            .background(Color.appPrimary)
                        }
                    } header: {
                        Button("LoadItems") {
                            Task {
                                await viewModel.send(.submit)
                            }
                        }
                        .buttonSizing(.flexible)
                        .padding(.vertical)
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .padding(Padding.md)
        }
        .applyBackground()
        .navigationTitle("Example")
        .task {
            await viewModel.send(.appear)
        }
        .refreshable {
            await viewModel.send(.refresh)
        }
    }
}
