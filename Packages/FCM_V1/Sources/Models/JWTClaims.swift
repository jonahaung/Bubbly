import Foundation
import SwiftJWT

struct JWTClaims: Claims {
	let iss: String
	let scope: String
	let aud: String
	let iat: Date
	let exp: Date
}
