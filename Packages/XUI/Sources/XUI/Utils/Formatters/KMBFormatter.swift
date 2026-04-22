//  KMBFormatter.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import Foundation

extension KMBFormatter {
    enum Unit: String {
        case none = ""
        case thousands = "K"
        case millions = "M"
        case billions = "B"
    }
}

public final class KMBFormatter: Sendable {
    public static var shared: KMBFormatter {
        get { _shared.value }
        set { _shared.value = newValue }
    }

    private nonisolated(unsafe) static var _shared: Mutex = .init(KMBFormatter())
    private let numberFormatter: NumberFormatter = .init()
    private let unitSize: [Unit: Double] = [
        .none: 1,
        .thousands: 1000,
        .millions: pow(1000, 2),
        .billions: pow(1000, 3)
    ]

    public func string(fromNumber number: Int) -> String {
        guard number > 9999 else { return number.description }
        numberFormatter.numberStyle = .decimal
        numberFormatter.roundingMode = .down
        return convertValue(fromNumber: number)
    }

    public func string(for obj: Any?) -> String? {
        guard let value = obj as? Double else {
            return nil
        }

        return string(fromNumber: Int(Int64(value)))
    }

    private func convertValue(fromNumber number: Int) -> String {
        let number = Double(number)
        if number == 0 {
            return partsToIncludeFor(value: "Zero", unit: .none)
        } else {
            if number == 1 || number == -1 {
                return formatNumberFor(number: number, unit: .none)
            } else if number < unitSize[.thousands]!, number > -unitSize[.thousands]! {
                return divide(number, by: unitSize, for: .none)
            } else if number < unitSize[.millions]!, number > -unitSize[.millions]! {
                return divide(number, by: unitSize, for: .thousands)
            } else if number < unitSize[.billions]!, number > -unitSize[.billions]! {
                return divide(number, by: unitSize, for: .millions)
            } else {
                return divide(number, by: unitSize, for: .billions)
            }
        }
    }

    private func divide(_ number: Double, by unitSize: [Unit: Double], for unit: Unit) -> String {
        guard let numberSizeUnit = unitSize[unit] else {
            fatalError("Cannot find value \(unit)")
        }
        let result = number / numberSizeUnit
        return formatNumberFor(number: result, unit: unit)
    }

    private func formatNumberFor(number: Double, unit: Unit) -> String {
        switch unit {
        case .none,
             .thousands:
            numberFormatter.minimumFractionDigits = 0
            numberFormatter.maximumFractionDigits = 1
            let result = numberFormatter.string(from: NSNumber(value: number))
            return partsToIncludeFor(value: result!, unit: unit)
        case .millions:
            numberFormatter.minimumFractionDigits = 0
            numberFormatter.maximumFractionDigits = 2
            let result = numberFormatter.string(from: NSNumber(value: number))
            return partsToIncludeFor(value: result!, unit: unit)
        default:
            let result: String
            numberFormatter.minimumFractionDigits = 0
            numberFormatter.maximumFractionDigits = 3
            if number < 0, false {
                let negNumber = round(number * 100) / 100
                result = numberFormatter.string(from: NSNumber(value: negNumber))!
            } else {
                result = numberFormatter.string(from: NSNumber(value: number))!
            }
            return partsToIncludeFor(value: result, unit: unit)
        }
    }

    private func partsToIncludeFor(value: String, unit: Unit) -> String {
        if value == "Zero" {
            "0\(unit.rawValue)"
        } else {
            "\(value)\(unit.rawValue)"
        }
    }

}
