// © 2026 Aung Ko Min

// import SwiftData
// import Foundation
//
// public struct PredicateBuilder<Root> {
//
//	private var builders: [(PredicateExpressions.Variable<Root>) -> any
//	StandardPredicateExpression<Bool>] = []
//
//	public init() {}
//
//	// MARK: - Equals
//
//	public mutating func equals<Value: Equatable>(
//		_ keyPath: KeyPath<Root, Value>,
//		_ value: Value
//	) -> Self {
//		builders.append { root in
//			PredicateExpressions.build_Equal(
//				lhs: PredicateExpressions.build_KeyPath(root: root, keyPath: keyPath),
//				rhs: PredicateExpressions.build_Arg(value)
//			)
//		}
//		return self
//	}
//
//	// MARK: - Not Equals
//
//	public mutating func notEquals<Value: Equatable>(
//		_ keyPath: KeyPath<Root, Value>,
//		_ value: Value
//	) -> Self {
//		builders.append { root in
//			PredicateExpressions.build_NotEqual(
//				lhs: PredicateExpressions.build_KeyPath(root: root, keyPath: keyPath),
//				rhs: PredicateExpressions.build_Arg(value)
//			)
//		}
//		return self
//	}
//
//	// MARK: - Comparison
//
//	public mutating func compare<Value>(
//		_ keyPath: KeyPath<Root, Value>,
//		_ op: PredicateExpressions.ComparisonOperator,
//		_ value: Value
//	) -> Self {
//		builders.append { root in
//			PredicateExpressions.build_Comparison(
//				lhs: PredicateExpressions.build_KeyPath(root: root, keyPath: keyPath),
//				rhs: PredicateExpressions.build_Arg(value),
//				op: op
//			)
//		}
//		return self
//	}
//
//	// MARK: - Build
//
//	public func build() -> Predicate<Root> {
//		#Predicate<Root> { root in
//			let variable = PredicateExpressions.Variable<Root>()
//
//			guard let first = builders.first?(variable) else { return true }
//
//			return builders.dropFirst().reduce(first) {
//				PredicateExpressions.Conjunction(
//					lhs: $0,
//					rhs: $1(variable)
//				)
//			}
//		}
//	}
// }
