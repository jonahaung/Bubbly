import Database

extension ChatComposer {
    struct State: Hashable, Sendable {
        var attachments: [Attachment] = []
        var menuIsOpened = false
        var source: Source?
        var isProcessing = false
    }
}
