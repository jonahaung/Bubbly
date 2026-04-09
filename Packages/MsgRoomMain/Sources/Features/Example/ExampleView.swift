//
//  Created by Aung Ko Min on 9/4/26.
//

import SwiftUI

struct ExampleView: View {
    @State private var viewModel = ExampleViewModel()

    var body: some View {
        VStack(spacing: 16) {
            if viewModel.state.isLoading {
                ProgressView()
            }

            if let error = viewModel.state.error {
                Text(error)
                    .foregroundStyle(.red)
            }

            Button("Submit") {
                Task {
                    await viewModel.send(.submit)
                }
            }
        }
        .padding()
        .navigationTitle("Example")
        .task {
            await viewModel.send(.appear)
        }
        .refreshable {
            await viewModel.send(.refresh)
        }
    }
}
