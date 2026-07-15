import Foundation
import Testing
@testable import BubblyBackend

@Suite
struct ValidationTests {
    @Test
    func acceptsValidE164Numbers() {
        #expect(Validation.isE164("+6591234567"))
        #expect(Validation.isE164("+14155552671"))
    }

    @Test
    func rejectsInvalidPhoneNumbers() {
        #expect(!Validation.isE164("6591234567"))
        #expect(!Validation.isE164("+012345678"))
        #expect(!Validation.isE164("+65 9123 4567"))
        #expect(!Validation.isE164("+٦٥٩١٢٣٤٥٦٧"))
    }

    @Test
    func validatesImageSignatures() {
        let png = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00])
        let jpeg = Data([0xFF, 0xD8, 0xFF, 0xE0])
        let webp = Data("RIFF0000WEBP".utf8)
        #expect(ImagePayloadValidator.isValid(data: png, contentType: "image/png"))
        #expect(ImagePayloadValidator.isValid(data: jpeg, contentType: "image/jpeg"))
        #expect(ImagePayloadValidator.isValid(data: webp, contentType: "image/webp"))
        #expect(!ImagePayloadValidator.isValid(data: png, contentType: "image/jpeg"))
    }
}
