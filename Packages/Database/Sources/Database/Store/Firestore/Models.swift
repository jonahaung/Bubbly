// © 2026 Aung Ko Min

import Foundation

// MARK: - FirestoreFilter

public struct FirestoreFilter {
    public enum Operator: String, Sendable {
        case equal = "EQUAL"
        case notEqual = "NOT_EQUAL"
        case lessThan = "LESS_THAN"
        case lessThanOrEqual = "LESS_THAN_OR_EQUAL"
        case greaterThan = "GREATER_THAN"
        case greaterThanOrEqual = "GREATER_THAN_OR_EQUAL"
        case arrayContains = "ARRAY_CONTAINS"
        case `in` = "IN"
        case arrayContainsAny = "ARRAY_CONTAINS_ANY"
    }

    public let field: String
    public let `operator`: Operator
    public let value: FSValue

    public init(field: String, operator: Operator, value: FSValue) {
        self.field = field
        self.operator = `operator`
        self.value = value
    }

    public var firestoreRepresentation: [String: Any] {
        [
            "fieldFilter": [
                "field": ["fieldPath": field],
                "op": `operator`.rawValue,
                "value": value.dictionary,
            ],
        ]
    }
}

// MARK: - FirestoreCollectionPath

public enum FirestoreCollectionPath: String, Sendable {
    case users
    case groups
}

// MARK: - FirestoreDocumentPath

public enum FirestoreDocumentPath: String, Sendable {
    case uid
    case members
    case mobile
}
