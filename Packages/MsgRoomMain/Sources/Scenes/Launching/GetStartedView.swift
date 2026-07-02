// © 2026 Aung Ko Min

import FirebaseAuth
import Services
import SwiftUI

struct GetStartedView: View {
    @Environment(AuthRouter.self) private var router
    let appLauncher: AppLauncher

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 0)
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .resizable()
                .scaledToFit()
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tint)
                .frame(width: 96, height: 96)
                .padding(.bottom, 8)

            VStack(spacing: 8) {
                Text("Welcome to Bubbly")
                    .font(.largeTitle.weight(.bold))
                    .multilineTextAlignment(.center)
                Text(
                    "Chat with friends, share moments, and stay connected. Let’s get you set up in a few seconds.",
                )
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            }

            Spacer(minLength: 0)

            Button {
                router.route(to: .signIn)
                router.startObservingAuthStateChanges()
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.roundedButtonStyle)
            .controlSize(.large)

            Button {
                // TODO: Present additional info, terms, or an onboarding carousel if desired.
            } label: {
                Text("Learn More")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)

            Text("You can customize your experience anytime in Settings.")
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
    }
}
