import Foundation

public let DISPATCH = DispatchQueue(label: "Stream", attributes: .concurrent)
public let cpuCount = ProcessInfo.processInfo.activeProcessorCount
