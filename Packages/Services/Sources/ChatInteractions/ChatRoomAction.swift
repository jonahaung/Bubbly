import Database
import SwiftUI

public extension EnvironmentValues {
	@Entry var sendChatRoomAction: (@Sendable (AnyMsgData) -> Void)?
}
