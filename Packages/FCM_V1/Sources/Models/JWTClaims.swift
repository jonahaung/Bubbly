//
//  JWTClaims.swift
//  FCM_V1
//
//  Created by Aung Ko Min on 10/5/25.
//

import Foundation
import SwiftJWT

struct JWTClaims: Claims {
    let iss: String
    let scope: String
    let aud: String
    let iat: Date
    let exp: Date
}
