//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

//
//  JWTHeader.swift
//  FCM_V1
//
//  Created by Aung Ko Min on 15/5/25.
//
import Foundation

struct JWTHeader: Encodable {
    let alg = "HS256"
    let typ = "JWT"
}
