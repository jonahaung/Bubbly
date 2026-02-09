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
	],
	targets: [
		.target(
			name: "MsgRoomMain",
			dependencies: [
				.product(name: "Services", package: "Services"),
			],
			resources: [
				.copy("Resources/emojis.json"),
			]
		),
		.testTarget(
			name: "MsgRoomMainTests",
			dependencies: ["MsgRoomMain"]
		),
	]
)
