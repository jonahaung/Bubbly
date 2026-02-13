import Foundation

public enum NetworkError: LocalizedError {
	case invalidURL
	case invalidResponse
	case unauthorized
	case serverError(Int)
	case decodingError(Error)
	case networkError(Error)
	case noData

	public var errorDescription: String? {
		switch self {
		case .invalidURL:
			"Invalid URL"
		case .invalidResponse:
			"Invalid response from server"
		case .unauthorized:
			"Unauthorized access"
		case let .serverError(code):
			"Server error: \(code)"
		case let .decodingError(error):
			"Failed to decode response: \(error.localizedDescription)"
		case let .networkError(error):
			"Network error: \(error.localizedDescription)"
		case .noData:
			"No data received"
		}
	}
}

public enum HTTPMethod: String {
	case get = "GET"
	case post = "POST"
	case put = "PUT"
	case patch = "PATCH"
	case delete = "DELETE"
}

public protocol Endpoint {
	var path: String { get }
	var method: HTTPMethod { get }
	var headers: [String: String]? { get }
	var parameters: [String: Any]? { get }
	var body: Data? { get }
}

public final class APIClient {
	private let baseURL: URL
	private let session: URLSession
	private let decoder: JSONDecoder
	private let encoder: JSONEncoder

	public init(baseURL: URL,
	            session: URLSession = .shared,
	            decoder: JSONDecoder = {
	            	let decoder = JSONDecoder()
	            	decoder.dateDecodingStrategy = .iso8601
	            	decoder.keyDecodingStrategy = .convertFromSnakeCase
	            	return decoder
	            }(),
	            encoder: JSONEncoder = {
	            	let encoder = JSONEncoder()
	            	encoder.dateEncodingStrategy = .iso8601
	            	encoder.keyEncodingStrategy = .convertToSnakeCase
	            	return encoder
	            }())
	{
		self.baseURL = baseURL
		self.session = session
		self.decoder = decoder
		self.encoder = encoder
	}
}
