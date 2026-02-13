import Foundation

public struct APNSNotification: Codable {
	public let validateOnly: Bool
	public let message: Message

	public struct Message: Codable {
		public let token: String
		public let data: DataPayload
		public let apns: APNS
	}

	public struct DataPayload: Codable {
		public let message: String
	}

	public struct APNS: Codable {
		public let payload: Payload
	}

	public struct Payload: Codable {
		public let aps: APS
	}

	public struct APS: Codable {
		public let alert: Alert
		public let mutableContent: Int
		public let contentAvailable: Int
		public let sound: String
		public let badge: Int

		enum CodingKeys: String, CodingKey {
			case mutableContent = "mutable-content"
			case contentAvailable = "content-available"
			case sound, badge, alert
		}

		public init(alert: Alert,
		            mutableContent: Bool = true,
		            contentAvailable: Bool = true,
		            sound: String = "default",
		            badge: Int = 1)
		{
			self.mutableContent = mutableContent ? 1 : 0
			self.contentAvailable = contentAvailable ? 1 : 0
			self.sound = sound
			self.badge = badge
			self.alert = alert
		}
	}

	public struct Alert: Codable, Sendable {
		public let title: String
		public let body: String

		public init(title: String, body: String) {
			self.title = title
			self.body = body
		}
	}

	public init(validateOnly: Bool = false,
	            deviceToken: String,
	            messageContent: String,
	            alert: APNSNotification.Alert)
	{
		self.validateOnly = validateOnly
		message = Message(
			token: deviceToken,
			data: DataPayload(message: messageContent),
			apns: APNS(
				payload: Payload(
					aps: APS(
						alert: alert
					)
				)
			)
		)
	}

	public func data(prettyPrinted: Bool = true) throws -> Data {
		let encoder = JSONEncoder()
		if prettyPrinted {
			encoder.outputFormatting = .prettyPrinted
		}
		return try encoder.encode(self)
	}
}
