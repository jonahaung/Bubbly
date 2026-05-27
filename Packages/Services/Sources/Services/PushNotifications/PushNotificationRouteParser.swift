import Core
import Database
import Foundation

public struct PushNotificationRouteParser: Sendable {
    public enum Error: Swift.Error {
        case invalidRoute(String)
        case missingRoute
    }

    private let codec: DeeplinkCodec

    public init(codec: DeeplinkCodec = .standard) {
        self.codec = codec
    }

    public func parse(userInfo: [AnyHashable: Any]) throws -> Deeplink {
        if let rawValue = userInfo["deep_link"] as? String {
            return try parseRouteString(rawValue)
        }

        if let rawValue = userInfo["deep_link"] as? NSString {
            return try parseRouteString(rawValue as String)
        }

        if let conID = userInfo["con_id"] as? String, !conID.isEmpty {
            return .conversation(conID: conID)
        }

        if let conID = userInfo["con_id"] as? NSString {
            let value = conID as String
            if !value.isEmpty {
                return .conversation(conID: value)
            }
        }

        let data = try AnyMsgData.parse(from: userInfo)
        return .conversation(conID: data.conID)
    }

    private func parseRouteString(_ rawValue: String) throws -> Deeplink {
        guard !rawValue.isEmpty else {
            throw Error.missingRoute
        }
        guard let url = URL(string: rawValue) else {
            throw Error.invalidRoute(rawValue)
        }
        switch codec.parse(url) {
        case .success(let route):
            return route
        case .failure(let error):
            throw error
        }
    }
}
