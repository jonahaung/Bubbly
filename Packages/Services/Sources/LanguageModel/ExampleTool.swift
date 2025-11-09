//
//  ExampleTool.swift
//  Services
//
//  Created by Aung Ko Min on 5/11/25.
//

import FoundationModels
import SwiftUI

public struct ExampleTool: Tool {
    public typealias Output = String
    public let name = "SendMessageToUser"
    public let description = "Send message to a user."

    @Generable public struct Arguments {
        @Guide(description: "The name of the user to send message to.")
        let name: String
    }

    func sendLoves(name: String) async {
        print("Sending message to \(name)")
    }

    public func call(arguments: Arguments) async throws -> Output {
        await sendLoves(name: arguments.name)
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        return Output("Love message to \(arguments.name)!")
    }
}
