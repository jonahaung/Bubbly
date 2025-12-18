//
//  URLSession++.swift
//  XUI
//
//  Created by Aung Ko Min on 16/12/25.
//

import Foundation

public extension URLSession {
	func synchronousDataTask(with url: URL) -> (Data?, URLResponse?, NSError?) {
		var data: Data?, response: URLResponse?, error: NSError?
		let semaphore = DispatchSemaphore(value: 0)

		dataTask(with: url, completionHandler: {
			data = $0; response = $1; error = $2 as NSError?
			semaphore.signal()
		}).resume()

		_ = semaphore.wait(timeout: DispatchTime.distantFuture)

		return (data, response, error)
	}

	func synchronousDataTask(with request: URLRequest) -> (Data?, URLResponse?, NSError?) {
		var data: Data?, response: URLResponse?, error: NSError?
		let semaphore = DispatchSemaphore(value: 0)

		dataTask(with: request, completionHandler: {
			data = $0; response = $1; error = $2 as NSError?
			semaphore.signal()
		}).resume()

		_ = semaphore.wait(timeout: DispatchTime.distantFuture)

		return (data, response, error)
	}
}
