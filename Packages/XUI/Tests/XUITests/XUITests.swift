//  XUITests.swift
//
//  Copyright © 2025 Aung Ko Min.
//

@testable import XUI
import Testing

@Test func inlineTokensPreserveLineLayout() {
    let result = MarkdownFormatter().richText(
        for: "Hello @alice, see #announcements"
    )

    #expect(String(result.characters) == "Hello @alice, see #announcements")
}

@Test func hashtagIsNotParsedAsHeading() {
    #expect(
        MarkdownParser.parse("#announcements")
            == [.paragraph(text: "#announcements")]
    )
}

@Test func headingRequiresMarkdownSeparator() {
    #expect(
        MarkdownParser.parse("## Release notes")
            == [.heading(level: 2, text: "Release notes")]
    )
}

@Test func nestedUnorderedListsPreserveBulletLayout() {
    let result = MarkdownFormatter().richText(for: "- Parent\n  - Child")

    #expect(String(result.characters) == "• Parent\n  • Child")
}

@Test func orderedListSupportsMultiDigitMarkers() {
    #expect(
        MarkdownParser.parse("100. Item")
            == [.orderedListItem(level: 0, index: 100, text: "Item")]
    )
}

@Test func unterminatedCodeFencePreservesContent() {
    #expect(
        MarkdownParser.parse("```swift\nlet value = 1")
            == [.codeBlock(language: "swift", content: "let value = 1")]
    )
}
