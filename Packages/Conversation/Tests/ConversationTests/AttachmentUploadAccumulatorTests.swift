import Database
import Testing
@testable import Conversation

struct AttachmentUploadAccumulatorTests {
    @Test
    func mixedAttachmentsCompleteAndPreserveOrder() {
        let first = attachment(id: "first", type: .imageUploading)
        let link = attachment(id: "link", type: .link)
        let third = attachment(id: "third", type: .imageUploading)
        let uploadedFirst = attachment(id: "first", type: .image, url: "remote-first")
        let uploadedThird = attachment(id: "third", type: .image, url: "remote-third")
        var accumulator = AttachmentUploadAccumulator()

        #expect(accumulator.complete(uploadedThird, in: [first, link, third]) == nil)
        let result = accumulator.complete(uploadedFirst, in: [first, link, third])

        #expect(result?.map(\.id) == ["first", "link", "third"])
        #expect(result?[0].url == "remote-first")
        #expect(result?[1] == link)
        #expect(result?[2].url == "remote-third")
    }

    @Test
    func duplicateCompletionDoesNotDispatchBatchTwice() {
        let pending = attachment(id: "image", type: .imageUploading)
        let uploaded = attachment(id: "image", type: .image, url: "remote")
        var accumulator = AttachmentUploadAccumulator()

        #expect(accumulator.complete(uploaded, in: [pending]) == [uploaded])
        #expect(accumulator.complete(uploaded, in: [pending]) == nil)
    }

    private func attachment(
        id: String,
        type: AttachMentType,
        url: String = "local"
    ) -> Attachment {
        Attachment(
            uid: id,
            url: url,
            attachMentTypeRaw: type.rawValue,
            aspectRatio: 1
        )
    }
}
