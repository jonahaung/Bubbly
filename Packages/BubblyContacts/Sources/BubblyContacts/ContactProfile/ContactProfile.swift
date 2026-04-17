import Database
import Services
import SwiftUI
import XUI
import Core

public struct ContactProfile: View {

    @State private var viewModel: ContactProfileViewModel
    @State private var contact: Contact
    @State private var properties: ConversationProperties

    public init(_ contact: Contact, coordinator _: AppCoordinator) {
        _viewModel = .init(wrappedValue: .init(contact: contact))
        _contact = .init(wrappedValue: contact)
        _properties = .init(wrappedValue: .init(uid: Conversation(.contact(contact)).uid))
    }

    public var body: some View {
        Form {
            Section {
                LabeledContent("Name") {
                    TextField("Name", text: $contact.name)
                        .textInputAutocapitalization(.words)
                }
            }
            Section {
                XNavPickerBar(
                    "Bubble Color",
                    BubbleColor.allCases,
                    $properties.theme.bubbleColor
                )
                XNavPickerBar(
                    "Chat Background",
                    ChatBackground.allCases,
                    $properties.theme.background
                )
                Stepper(
                    "Cornor Radius - \(properties.theme.bubbleCornorRadius.int)",
                    value: $properties.theme.bubbleCornorRadius
                )
            }
            Section {
                AsyncButton {
                    await viewModel.send(.deleteMessages)
                } label: {
                    Text("Delete Messages")
                }
                .disabled(viewModel.state.isLoading || viewModel.state.isDeletingMessages)
            }
            if let error = viewModel.state.error {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }
            Section {} footer: {
                Text(contact.preetyPrinted)
                    .textSelection(.enabled)
            }
        }
        .navigationTitle(contact.name)
        .navigationBarBackButtonHidden(viewModel.state.isLoading || viewModel.state.isDeletingMessages)
        .toolbar {
            if viewModel.state.isLoading || viewModel.state.isDeletingMessages {
                ToolbarItem(placement: .topBarTrailing) {
                    ProgressView()
                        .controlSize(.mini)
                }
            }
        }
        .task {
            await viewModel.send(.appear)
        }
        .refreshable {
            await viewModel.send(.refresh)
        }
        .onChange(of: contact) { _, newValue in
            Task {
                await viewModel.send(.updateContact(newValue))
            }
        }
        .onChange(of: properties) { _, newValue in
            Task {
                await viewModel.send(.updateProperties(newValue))
            }
        }
        .onChange(of: viewModel.state.contact) { _, newValue in
            guard contact != newValue else {
                return
            }
            contact = newValue
        }
        .onChange(of: viewModel.state.properties) { _, newValue in
            guard properties != newValue else {
                return
            }
            properties = newValue
        }
    }
}
