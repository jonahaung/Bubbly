import Database
import SwiftUI
import Core

struct BackendBaseURLSettingsView: View {
    @State private var baseURL: String
    @State private var hasOverride: Bool
    @State private var validationMessage: String?

    init() {
        let override = HTTPClientConfiguration.applicationBaseURLOverride
        let configuredBaseURL = try? HTTPClientConfiguration.application().baseURL.absoluteString
        _baseURL = State(initialValue: override ?? configuredBaseURL ?? "")
        _hasOverride = State(initialValue: override != nil)
    }

    var body: some View {
        ScrollSectionContent {
            TextField("https://api.example.com", text: $baseURL)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit(save)

            if let validationMessage {
                Text(validationMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Button("Save Base URL", action: save)
                .disabled(baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Button("Use Build Configuration", action: reset)
                .disabled(!hasOverride)
        } header: {
            Text("Backend")
        } footer: {
            Text(
                "Changes apply to new network requests immediately. Reset to use the URL configured by the active Xcode scheme or build settings."
            )
        }
    }

    private func save() {
        do {
            try HTTPClientConfiguration.setApplicationBaseURLOverride(baseURL)
            baseURL = HTTPClientConfiguration.applicationBaseURLOverride ?? ""
            hasOverride = true
            validationMessage = nil
        } catch {
            validationMessage = "Enter a valid HTTP or HTTPS URL without credentials, a query, or a fragment."
        }
    }

    private func reset() {
        try? HTTPClientConfiguration.setApplicationBaseURLOverride(nil)
        baseURL = (try? HTTPClientConfiguration.application().baseURL.absoluteString) ?? ""
        hasOverride = false
        validationMessage = nil
    }
}
