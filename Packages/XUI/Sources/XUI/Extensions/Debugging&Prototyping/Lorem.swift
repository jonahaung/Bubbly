//
//  Lorem.swift
//  HomeForYou
//
//  Semantic Lorem Generator
//  Chat-aware, Emoji-aware, i18n-ready
//

import Foundation

// MARK: - Public Configuration
public enum LoremTone {
	case neutral
	case friendly
}

public struct LoremConversationContext {
	public let previousMessage: String?

	public init(previousMessage: String?) {
		self.previousMessage = previousMessage
	}
}

public enum LoremDomain {
	case generic
	case chat
}

public enum LoremEmojiPolicy {
	case none
	case light
	case expressive
}

public struct LoremConfiguration {
	public var domain: LoremDomain
	public var emoji: LoremEmojiPolicy
	public var locale: Locale
	public var tone: LoremTone

	@MainActor
	public static let `default` = LoremConfiguration(
		domain: .generic,
		emoji: .none,
		locale: .current,
		tone: .neutral
	)
}

// MARK: - Lorem
@MainActor
public enum Lorem {

	// MARK: Configuration

	public static var configuration = LoremConfiguration.default

	// MARK: - Words

	public static var word: String {
		sentencePack.words.randomElement()!
	}

	public static func words(_ count: Int) -> String {
		compose(word, count: count, joinBy: .space)
	}

	public static func words(_ range: Range<Int>) -> String {
		compose(word, count: .random(in: range), joinBy: .space)
	}

	public static func words(_ range: ClosedRange<Int>) -> String {
		compose(word, count: .random(in: range), joinBy: .space)
	}

	// MARK: - Sentences

	public static var sentence: String {
		let pack = sentencePack

		let base: String = {
			switch configuration.domain {
			case .chat:
				return pack.chatTemplates.random()()
			case .generic:
				return pack.genericTemplates.random()()
			}
		}()

		return decorateWithEmoji(base) + "."
	}

	public static func sentences(_ count: Int) -> String {
		compose(sentence, count: count, joinBy: .space)
	}

	public static func sentences(_ range: Range<Int>) -> String {
		compose(sentence, count: .random(in: range), joinBy: .space)
	}

	public static func sentences(_ range: ClosedRange<Int>) -> String {
		compose(sentence, count: .random(in: range), joinBy: .space)
	}

	public static func random() -> String {
		[
			sentence,
			tweet,
			paragraph,
			title,
			shortTweet,
			url.absoluteString,
			reply(to: .init(previousMessage: sentence))
		].random()
	}

	// MARK: - Paragraphs

	public static var paragraph: String {
		compose(
			sentence,
			count: .random(in: minSentencesCountInParagraph...maxSentencesCountInParagraph),
			joinBy: .space
		)
	}

	public static func paragraphs(_ count: Int) -> String {
		compose(paragraph, count: count, joinBy: .newLine)
	}

	public static func paragraphs(_ range: Range<Int>) -> String {
		compose(paragraph, count: .random(in: range), joinBy: .newLine)
	}

	public static func paragraphs(_ range: ClosedRange<Int>) -> String {
		compose(paragraph, count: .random(in: range), joinBy: .newLine)
	}

	// MARK: - Titles

	public static var title: String {
		compose(
			word,
			count: .random(in: minWordsCountInTitle...maxWordsCountInTitle),
			joinBy: .space,
			decorate: { $0.capitalized }
		)
	}

	// MARK: - Tweets

	public static var shortTweet: String {
		composeTweet(shortTweetMaxLength)
	}

	public static var tweet: String {
		composeTweet(tweetMaxLength)
	}

	// MARK: - Names

	public static var firstName: String {
		sentencePack.firstNames.random()
	}

	public static var lastName: String {
		sentencePack.lastNames.random()
	}

	public static var fullName: String {
		"\(firstName) \(lastName)"
	}

	// MARK: - Email & URLs

	public static var emailAddress: String {
		"\(firstName).\(lastName)@\(sentencePack.emailDomains.random())".lowercased()
	}

	public static var url: URL {
		URL(string: sentencePack.urls.random())!
	}
}

// MARK: - Sentence Packs (i18n-ready)

private protocol LoremSentencePack {
	var words: [String] { get }
	var chatTemplates: [() -> String] { get }
	var replyTemplates: [(String) -> String] { get }  // 👈 NEW
	var genericTemplates: [() -> String] { get }
	var emojisLight: [String] { get }
	var emojisExpressive: [String] { get }
	var firstNames: [String] { get }
	var lastNames: [String] { get }
	var emailDomains: [String] { get }
	var urls: [String] { get }
}

// MARK: - English Pack

private struct EnglishSentencePack: LoremSentencePack {

	// MARK: - Vocabulary (used by word/title generators)

	let words = [
		"message", "system", "user", "feature", "update",
		"conversation", "service", "experience", "design",
		"performance", "security", "workflow", "notification",
		"account", "profile", "session", "request",
		"response", "timeline", "status", "delivery",
		"support", "issue", "confirmation", "details",
		"information", "summary", "progress", "result"
	]

	// MARK: - Chat Templates (openers, questions, updates)

	let chatTemplates: [() -> String] = [

		// Openers
		{ "Hey, are you free right now" },
		{ "Hi, do you have a moment" },
		{ "Just checking in with you" },
		{ "Hope you are doing well" },
		{ "Hey there, quick question" },

		// Follow-ups
		{ "I wanted to follow up on this" },
		{ "Just following up on my earlier message" },
		{ "Any updates on this so far" },
		{ "Let me know if you had a chance to check" },

		// Status updates
		{ "I am looking into this now" },
		{ "I am still checking on this" },
		{ "I will get back to you shortly" },
		{ "I should have an update soon" },
		{ "Let me check and update you" },

		// Requests
		{ "Can you help me with this" },
		{ "Could you share more details" },
		{ "Can you send me the details later" },
		{ "Do you need anything else from me" },

		// Scheduling
		{ "Can we discuss this later today" },
		{ "Let us continue this later" },
		{ "We can revisit this tomorrow if needed" },

		// Confirmations
		{ "That sounds good to me" },
		{ "That should be fine" },
		{ "Okay, that works for me" },

		// Closings
		{ "Thanks for checking on this" },
		{ "Appreciate your help here" },
		{ "Thanks, talk to you soon" }
	]

	// MARK: - Generic / System Messages (UI, banners, logs)

	let genericTemplates: [() -> String] = [

		{
			"The application is running smoothly, and all core features are currently available without any interruptions."
		},

		{
			"This feature has been designed to improve the overall user experience by making common actions faster and easier to complete."
		},

		{
			"The system processes requests efficiently in the background to ensure a responsive and reliable experience for all users."
		},

		{
			"The latest update enhances overall performance while also improving stability and reducing unexpected issues."
		},

		{
			"The workflow has been updated successfully, and the changes will take effect the next time the application is opened."
		},

		{
			"Notifications are delivered in real time so that important updates and messages are not missed."
		},

		{
			"Security checks are completed automatically to protect your data and maintain a safe and trusted environment."
		},

		{
			"The service is currently operating normally, and no outages or maintenance activities are affecting availability."
		},

		{
			"Your request has been received successfully and is now being processed by the system."
		},

		{
			"Changes have been saved successfully, and no further action is required at this time."
		},

		{
			"The system is temporarily unavailable due to scheduled maintenance, and services will resume shortly."
		},

		{
			"Please try again later if the issue persists, or contact support for further assistance."
		},

		{
			"Some features may be limited while background updates are in progress, but normal functionality will return soon."
		},

		{
			"We are currently performing routine maintenance to improve reliability and long-term performance."
		},

		{
			"Your settings have been updated and will be applied across all devices linked to your account."
		},

		{
			"Data synchronization is in progress to ensure that your information remains up to date."
		},

		{
			"No further action is required unless you receive additional instructions from the system."
		},

		{
			"If you continue to experience issues, please restart the application and try again."
		}
	]

	// MARK: - Reply Templates (reply-aware, friendly)

	let replyTemplates: [(String) -> String] = [

		// Acknowledgements
		{ _ in "Sure, that works for me" },
		{ _ in "Yep, I can do that" },
		{ _ in "Sounds good, thanks for checking" },
		{ _ in "No problem at all" },
		{ _ in "Got it, thanks for letting me know" },

		// Action replies
		{ _ in "I am on it now" },
		{ _ in "I will take care of this" },
		{ _ in "Let me check and get back to you" },
		{ _ in "I will confirm and update you shortly" },

		// Clarifications
		{ _ in "Could you clarify this part for me" },
		{ _ in "Just to confirm, is this correct" },
		{ _ in "Let me make sure I understood this correctly" },

		// Delays
		{ _ in "Sorry for the delay, I am checking now" },
		{ _ in "Thanks for your patience on this" },

		// Context-aware reply
		{ previous in
			"I saw your message about \(previous.lowercased())"
		}
	]

	// MARK: - Emojis

	let emojisLight = [
		"🙂", "👍", "👌", "😊", "🤝", "✨"
	]

	let emojisExpressive = [
		"😂", "🔥", "🚀", "🙌", "😅", "🎉", "💯"
	]

	// MARK: - Names

	let firstNames = [
		"Alex", "Jamie", "Taylor", "Jordan", "Chris", "Morgan",
		"Sam", "Casey", "Avery", "Riley", "Drew", "Quinn",
		"Ryan", "Shawn", "Daniel", "Ethan", "Sophia", "Emma"
	]

	let lastNames = [
		"Lee", "Tan", "Ng", "Smith", "Johnson",
		"Brown", "Wong", "Lim", "Chen", "Park",
		"Wilson", "Anderson", "Harris"
	]

	// MARK: - Internet

	let emailDomains = [
		"gmail.com",
		"icloud.com",
		"outlook.com",
		"yahoo.com",
		"proton.me"
	]

	let urls = [
		"https://www.simplygo.com.sg",
		"https://github.com",
		"https://apple.com",
		"https://developer.apple.com",
		"https://figma.com",
		"https://support.apple.com"
	]
}

// MARK: - Internal Helpers

extension Lorem {

	fileprivate static var sentencePack: LoremSentencePack {
		switch configuration.locale.language.languageCode?.identifier {
		case "en", .none:
			return EnglishSentencePack()
		default:
			return EnglishSentencePack()
		}
	}

	fileprivate static func decorateWithEmoji(_ sentence: String) -> String {
		switch configuration.emoji {
		case .none:
			return sentence
		case .light:
			guard Bool.random() else { return sentence }
			return "\(sentence) \(sentencePack.emojisLight.random())"
		case .expressive:
			return "\(sentence) \(sentencePack.emojisExpressive.random())"
		}
	}

	fileprivate enum Separator: String {
		case space = " "
		case newLine = "\n"
	}

	fileprivate static func compose(
		_ provider: @autoclosure () -> String,
		count: Int,
		joinBy separator: Separator,
		decorate: ((String) -> String)? = nil
	) -> String {
		let result = (0..<count)
			.map { _ in provider() }
			.joined(separator: separator.rawValue)

		return decorate?(result) ?? result
	}

	public static func composeTweet(_ maxLength: Int) -> String {
		for count in [4, 3, 2, 1] {
			let text = sentences(count)
			if text.count <= maxLength {
				return text
			}
		}
		return sentence
	}

	public static func reply(
		to context: LoremConversationContext
	) -> String {

		let pack = sentencePack

		let base: String = {
			guard
				configuration.domain == .chat,
				let previous = context.previousMessage,
				configuration.tone == .friendly
			else {
				return sentence
			}

			return pack.replyTemplates.random()(previous)
		}()

		return decorateWithEmoji(base) + "."
	}
	fileprivate static let minSentencesCountInParagraph = 3
	fileprivate static let maxSentencesCountInParagraph = 7
	fileprivate static let minWordsCountInTitle = 2
	fileprivate static let maxWordsCountInTitle = 6
	fileprivate static let shortTweetMaxLength = 140
	fileprivate static let tweetMaxLength = 280
}
extension Lorem {
	fileprivate static func applyTone(_ sentence: String) -> String {
		switch configuration.tone {
		case .neutral:
			return sentence
		case .friendly:
			return Bool.random()
				? sentence
				: "Hey! \(sentence.lowercased())"
		}
	}
}
// MARK: - Convenience

extension Array {
	fileprivate func random() -> Element {
		randomElement()!
	}
}
