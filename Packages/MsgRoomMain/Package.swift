// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "MsgRoomMain",
	platforms: [.iOS(.v26)],
	products: [
		.library(
			name: "MsgRoomMain",
			targets: ["MsgRoomMain"]
		),
	],
	dependencies: [
		.package(name: "Services", path: "../Services"),
		.package(name: "Database", path: "../Database"),
		.package(name: "Conversation", path: "../Conversation"),
		.package(name: "Inbox", path: "../Inbox"),
		.package(name: "Settings", path: "../Settings"),
		.package(url: "https://github.com/apple/swift-collections", from: "1.1.0"),
	],
	targets: [
		.target(
			name: "MsgRoomMain",
			dependencies: [
				.product(name: "Services", package: "Services"),
				.product(name: "Database", package: "Database"),
				.product(name: "Conversation", package: "Conversation"),
				.product(name: "Inbox", package: "Inbox"),
				.product(name: "Settings", package: "Settings"),
				.product(name: "Collections", package: "swift-collections"),
			]
		),
		.testTarget(
			name: "MsgRoomMainTests",
			dependencies: [
				"MsgRoomMain",
				.product(name: "Services", package: "Services"),
				.product(name: "Database", package: "Database"),
				.product(name: "Conversation", package: "Conversation"),
				.product(name: "Inbox", package: "Inbox"),
				.product(name: "Settings", package: "Settings"),
				.product(name: "Collections", package: "swift-collections"),
			]
		),
	]
)

