//
//  PushNotificationError.swift
//  FCM_V1
//
//  Created by Aung Ko Min on 10/5/25.
//
import Foundation

public enum PushNotificationError: Error {
	case serviceAccountNotFound
	case invalidPrivateKey
	case invalidTokenURL
	case invalidURL
	case noDataReceived
	case tokenGenerationFailed
	case tokenDecodingFailed
}
