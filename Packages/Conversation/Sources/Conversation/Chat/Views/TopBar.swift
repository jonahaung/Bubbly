import Core
import Database
import Services
import SwiftUI
import XUI

struct TopBar: View {

	// MARK: Internal

	var body: some View {
		ZStack(alignment: .top) {
			CustomButton {
				UIApplication.shared.endEditing()
			} label: {
				HStack {
					switch manager.state.conversation.kind {
					case let .contact(contact):
						ProfilePhoto(
							contact,
							config: .init(
								size: .custom(30),
								processors: [.circle(border: .init(color: .green, width: 2)), .sticker()]
							)
						)
					case let .group(group):
						ProfilePhoto(
							group,
							config: .init(size: .custom(30), processors: [.circle(), .sticker()])
						)
					}
					Text(manager.state.conversation.name)
						.font(.subheadline.weight(.semibold))
						.lineHeight(.multiple(factor: 1.2))
						.badgeView(
							Text(
								manager.conversationConfig.totalMsgsCount,
								format: .number
							)
							.font(
								.caption.italic().width(.compressed).weight(.semibold)
							)
							.lineHeight(.multiple(factor: 1.2))
						)
				}
			} onFinished: {
				Router.shared.pushToNav(.conversationDetails(manager.state.conversation))
			}
			HStack(alignment: .top) {
				CustomButton {
					dismiss()
				} label: {
					Image(systemSymbol: .chevronBackward)
						.frame(square: 44)
						.background(.background, in: .circle)
				}
				Spacer()

				AsyncButton {
					let id = manager.state.conversation.members.random()
					try await AsyncOrderedStream.mapOrdered(inputs: Array(0...1000)) { i in
						let msg = await Message(
							uid: IDGenerator.shared.make(),
							senderID: [currentUserID!, id].random(),
							conID: manager.conversationConfig.conID,
							text: Lorem.random(),
							date: Date.now
								.addingTimeInterval(-(i * [60, 10000, 5000, 100].random()).double),
							deliveryStatus: .delivered,
							attachments: [],
							reactions: []
						)
						try await Store.shared.msgStore?.insert(msg)

					}

					@Sendable func randomDateInCurrentWeek() -> Date? {
						let calendar = Calendar.current
						let now = Date()

						// Get start of the week
						guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else {
							return nil
						}

						let start = weekInterval.start
						let end = weekInterval.end

						// Random time interval between start and end
						let randomTime = TimeInterval.random(in: start.timeIntervalSince1970...end.timeIntervalSince1970)

						return Date(timeIntervalSince1970: randomTime)
					}
				} label: {
					Image(systemSymbol: .quoteClosing)
				}
				.frame(square: 44)
				.background(.background, in: .circle)
			}
			.padding(.horizontal, 8)
			.padding(.bottom, 8)
		}
		.background(
			LinearGradient(
				colors: [
					manager.state.properties.theme.background.color,
					.clear
				],
				startPoint: .top,
				endPoint: .bottom
			)
		)
		.geometryGroup()
		.equatable(by: manager.state)
	}

	// MARK: Private

	@Environment(ChatManager.self) private var manager
	@Environment(\.dismiss) private var dismiss
}
