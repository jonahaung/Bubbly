import Database

extension ChatComposer {
    func handlePrimaryAction(_ conversation: Conversation) {
        send(conversation: conversation)
    }

    func handleSecondaryAction(_ conversation: Conversation) {
        if hasContent {
            send(conversation: conversation)
        } else {
            resetSource()
        }
    }

    func resetSource() {
        state.source = nil
    }

    func send(conversation: Conversation) {
        guard canSend else {
            return
        }

        let text = inputText.text.string.trimmed
        let attachments = state.attachments
        resetDraft()

        queue.addOperation { [weak self, msgCreator, worker] in
            do {
                try await worker.sendMessage(
                    text: text,
                    attachments: attachments,
                    conversation: conversation,
                    msgCreator: msgCreator
                )
            } catch {
                await self?.showError(error)
            }
        }
    }

    func resetDraft() {
        inputText.clear()
        photoPicker.removeAll()
        state.attachments.removeAll()
        state.source = nil
        state.isProcessing = false
    }
}
