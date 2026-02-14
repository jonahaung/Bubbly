// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
	name: "ImageLoader",
	platforms: [
		.iOS(.v17),
	],
	products: [
		.library(name: "ImageLoader", targets: ["ImageLoader"]),
		.library(name: "VideoLoader", targets: ["VideoLoader"]),
	],
	targets: [
		// Core image loading target has no dependencies
		.target(
			name: "ImageLoader",
			dependencies: []
		),
		// VideoLoader builds on top of ImageLoader
		.target(
			name: "VideoLoader",
			dependencies: ["ImageLoader"]
		),
	]
)
