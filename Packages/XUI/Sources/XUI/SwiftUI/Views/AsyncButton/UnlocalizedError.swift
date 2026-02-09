import Foundation

struct UnlocalizedError: LocalizedError {
	let errorDescription: String?

	init(error: Error) {
		errorDescription = error.localizedDescription
	}
}
