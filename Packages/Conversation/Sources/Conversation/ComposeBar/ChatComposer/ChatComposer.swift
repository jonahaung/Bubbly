import Database
import Foundation
import Observation
import Services
import XUI

@MainActor
@Observable
final class ChatComposer: ErrorPresenter {
   
    var state = State()
    var selection = [URL]()
    var lookUp: URL?
    @ObservationIgnored var inputText = InputText()
    @ObservationIgnored let msgCreator: MsgCreator
    @ObservationIgnored let worker: ChatComposerWorker
    @ObservationIgnored let queue: AsyncQueue

    init(
        msgCreator: MsgCreator = MsgCreator(),
        worker: ChatComposerWorker = ChatComposerWorker(),
        queue: AsyncQueue = AsyncQueue()
    ) {
        self.msgCreator = msgCreator
        self.worker = worker
        self.queue = queue
        inputText.delegate = self
    }

    var hasContent: Bool {
        inputText.hasText || !state.attachments.isEmpty
    }

    var canSend: Bool {
        hasContent && !state.isProcessing
    }

    func updateSource(_ source: Source?) {
        if state.source == source {
            state.source = nil
            return
        }

        state.source = source
        if source?.keepsMenuOpen == false {
            state.menuIsOpened = false
        }
    }

    func setProcessing(_ isProcessing: Bool) {
        state.isProcessing = isProcessing
    }
}
