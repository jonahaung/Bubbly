//  ContactProfileAction.swift
//
//  Copyright © 2026 Aung Ko Min.
//

enum ContactProfileAction {
    case setLoading(Bool)
    case setDeletingMessages(Bool)
    case setError(String?)
    case applySnapshot(ContactProfileSnapshot)
}
