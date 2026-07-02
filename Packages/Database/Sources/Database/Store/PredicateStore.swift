//  PredicateStore.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import Core
import SwiftData
import Foundation

public enum PMsgPredicates {
    public static func deliveryStatus(
        conID: String,
        currentUserID: String,
        recipient: MsgRecipient,
        deliveryStatus: DeliveryStatus,
        comparison: PredicateExpressions.ComparisonOperator
    ) -> Predicate<PMsg> {
        let value = deliveryStatus.rawValue
        switch recipient {
        case .outgoing:
            switch comparison {
            case .lessThan:
                return Foundation.Predicate<PMsg>({ arg in
                    PredicateExpressions.build_Conjunction(
                        lhs: PredicateExpressions.build_Conjunction(
                            lhs: conIDExpression(arg),
                            rhs: senderExpression(arg)
                        ),
                        rhs: PredicateExpressions.build_Comparison(
                            lhs: PredicateExpressions.build_KeyPath(
                                root: PredicateExpressions.build_Arg(arg),
                                keyPath: \.deliveryStatusAggregateRaw
                            ),
                            rhs: PredicateExpressions.build_Arg(value),
                            op: .lessThan
                        )
                    )
                })
            case .lessThanOrEqual:
                return Foundation.Predicate<PMsg>({ arg in
                    PredicateExpressions.build_Conjunction(
                        lhs: PredicateExpressions.build_Conjunction(
                            lhs: conIDExpression(arg),
                            rhs: senderExpression(arg)
                        ),
                        rhs: PredicateExpressions.build_Comparison(
                            lhs: PredicateExpressions.build_KeyPath(
                                root: PredicateExpressions.build_Arg(arg),
                                keyPath: \.deliveryStatusAggregateRaw
                            ),
                            rhs: PredicateExpressions.build_Arg(value),
                            op: .lessThanOrEqual
                        )
                    )
                })
            case .greaterThan:
                return Foundation.Predicate<PMsg>({ arg in
                    PredicateExpressions.build_Conjunction(
                        lhs: PredicateExpressions.build_Conjunction(
                            lhs: conIDExpression(arg),
                            rhs: senderExpression(arg)
                        ),
                        rhs: PredicateExpressions.build_Comparison(
                            lhs: PredicateExpressions.build_KeyPath(
                                root: PredicateExpressions.build_Arg(arg),
                                keyPath: \.deliveryStatusAggregateRaw
                            ),
                            rhs: PredicateExpressions.build_Arg(value),
                            op: .greaterThan
                        )
                    )
                })
            case .greaterThanOrEqual:
                return Foundation.Predicate<PMsg>({ arg in
                    PredicateExpressions.build_Conjunction(
                        lhs: PredicateExpressions.build_Conjunction(
                            lhs: conIDExpression(arg),
                            rhs: senderExpression(arg)
                        ),
                        rhs: PredicateExpressions.build_Comparison(
                            lhs: PredicateExpressions.build_KeyPath(
                                root: PredicateExpressions.build_Arg(arg),
                                keyPath: \.deliveryStatusAggregateRaw
                            ),
                            rhs: PredicateExpressions.build_Arg(value),
                            op: .greaterThanOrEqual
                        )
                    )
                })
            default:
                return Foundation.Predicate<PMsg>({ arg in
                    PredicateExpressions.build_Conjunction(
                        lhs: PredicateExpressions.build_Conjunction(
                            lhs: conIDExpression(arg),
                            rhs: senderExpression(arg)
                        ),
                        rhs: PredicateExpressions.build_Equal(
                            lhs: PredicateExpressions.build_KeyPath(
                                root: PredicateExpressions.build_Arg(arg),
                                keyPath: \.deliveryStatusAggregateRaw
                            ),
                            rhs: PredicateExpressions.build_Arg(value)
                        )
                    )
                })
            }

        case .incoming:
            switch comparison {
            case .lessThan:
                return Foundation.Predicate<PMsg>({ arg in
                    PredicateExpressions.build_Conjunction(
                        lhs: PredicateExpressions.build_Conjunction(
                            lhs: conIDExpression(arg),
                            rhs: notSenderExpression(arg)
                        ),
                        rhs: PredicateExpressions.build_Comparison(
                            lhs: PredicateExpressions.build_KeyPath(
                                root: PredicateExpressions.build_Arg(arg),
                                keyPath: \.incomingStatus
                            ),
                            rhs: PredicateExpressions.build_Arg(value),
                            op: .lessThan
                        )
                    )
                })
            case .lessThanOrEqual:
                return Foundation.Predicate<PMsg>({ arg in
                    PredicateExpressions.build_Conjunction(
                        lhs: PredicateExpressions.build_Conjunction(
                            lhs: conIDExpression(arg),
                            rhs: notSenderExpression(arg)
                        ),
                        rhs: PredicateExpressions.build_Comparison(
                            lhs: PredicateExpressions.build_KeyPath(
                                root: PredicateExpressions.build_Arg(arg),
                                keyPath: \.incomingStatus
                            ),
                            rhs: PredicateExpressions.build_Arg(value),
                            op: .lessThanOrEqual
                        )
                    )
                })
            case .greaterThan:
                return Foundation.Predicate<PMsg>({ arg in
                    PredicateExpressions.build_Conjunction(
                        lhs: PredicateExpressions.build_Conjunction(
                            lhs: conIDExpression(arg),
                            rhs: notSenderExpression(arg)
                        ),
                        rhs: PredicateExpressions.build_Comparison(
                            lhs: PredicateExpressions.build_KeyPath(
                                root: PredicateExpressions.build_Arg(arg),
                                keyPath: \.incomingStatus
                            ),
                            rhs: PredicateExpressions.build_Arg(value),
                            op: .greaterThan
                        )
                    )
                })
            case .greaterThanOrEqual:
                return Foundation.Predicate<PMsg>({ arg in
                    PredicateExpressions.build_Conjunction(
                        lhs: PredicateExpressions.build_Conjunction(
                            lhs: conIDExpression(arg),
                            rhs: notSenderExpression(arg)
                        ),
                        rhs: PredicateExpressions.build_Comparison(
                            lhs: PredicateExpressions.build_KeyPath(
                                root: PredicateExpressions.build_Arg(arg),
                                keyPath: \.incomingStatus
                            ),
                            rhs: PredicateExpressions.build_Arg(value),
                            op: .greaterThanOrEqual
                        )
                    )
                })
            default:
                return Foundation.Predicate<PMsg>({ arg in
                    PredicateExpressions.build_Conjunction(
                        lhs: PredicateExpressions.build_Conjunction(
                            lhs: conIDExpression(arg),
                            rhs: notSenderExpression(arg)
                        ),
                        rhs: PredicateExpressions.build_Equal(
                            lhs: PredicateExpressions.build_KeyPath(
                                root: PredicateExpressions.build_Arg(arg),
                                keyPath: \.incomingStatus
                            ),
                            rhs: PredicateExpressions.build_Arg(value)
                        )
                    )
                })
            }
        case .system:
            fatalError()
        }
        
        func conIDExpression(_ arg: PredicateExpressions.Variable<PMsg>) -> PredicateExpressions
        .Equal<PredicateExpressions.KeyPath<PredicateExpressions.Variable<PMsg>, String>, PredicateExpressions.Value<String>> {
            PredicateExpressions.build_Equal(
                lhs: PredicateExpressions.build_KeyPath(
                    root: PredicateExpressions.build_Arg(arg),
                    keyPath: \.conID
                ),
                rhs: PredicateExpressions.build_Arg(conID)
            )
        }

        func notSenderExpression(_ arg: PredicateExpressions.Variable<PMsg>) -> PredicateExpressions
        .NotEqual<PredicateExpressions.KeyPath<PredicateExpressions.Variable<PMsg>, String>, PredicateExpressions.Value<String>> {
            PredicateExpressions.build_NotEqual(
                lhs: PredicateExpressions.build_KeyPath(
                    root: PredicateExpressions.build_Arg(arg),
                    keyPath: \.senderID
                ),
                rhs: PredicateExpressions.build_Arg(currentUserID)
            )
        }

        func senderExpression(_ arg: PredicateExpressions.Variable<PMsg>) -> PredicateExpressions
        .Equal<PredicateExpressions.KeyPath<PredicateExpressions.Variable<PMsg>, String>, PredicateExpressions.Value<String>> {
            PredicateExpressions.build_Equal(
                lhs: PredicateExpressions.build_KeyPath(
                    root: PredicateExpressions.build_Arg(arg),
                    keyPath: \.senderID
                ),
                rhs: PredicateExpressions.build_Arg(currentUserID)
            )
        }

    }

    public static func deliveryStatusEqual(
        conID: String,
        currentUserID: String,
        recipient: MsgRecipient,
        incomingStatus: DeliveryStatus
    ) -> Predicate<PMsg> {
        let value = incomingStatus.rawValue

        switch recipient {
        case .outgoing:
            return #Predicate<PMsg> {
                $0.conID == conID &&
                    $0.senderID == currentUserID &&
                    $0.deliveryStatusAggregateRaw == value
            }

        case .incoming:
            let value = incomingStatus.rawValue
            return #Predicate<PMsg> {
                $0.conID == conID &&
                    $0.senderID != currentUserID &&
                    $0.incomingStatus == value
            }

        case .system:
            fatalError()
        }
    }

    public static func conID(_ value: String) -> Predicate<PMsg> {
        #Predicate<PMsg> { $0.conID == value }
    }

    public static func notSender(_ value: String) -> Predicate<PMsg> {
        #Predicate<PMsg> { $0.senderID != value }
    }

    public static func delivery(
        _ op: PredicateExpressions.ComparisonOperator,
        _ status: DeliveryStatus
    ) -> Predicate<PMsg> {
        let value = status.rawValue
        switch op {
        case .lessThan: return #Predicate<PMsg> { $0.deliveryStatusAggregateRaw < value }
        case .lessThanOrEqual: return #Predicate<PMsg> { $0.deliveryStatusAggregateRaw <= value }
        case .greaterThan: return #Predicate<PMsg> { $0.deliveryStatusAggregateRaw > value }
        case .greaterThanOrEqual:
            return #Predicate<PMsg> { $0.deliveryStatusAggregateRaw >= value }
        @unknown default:
            return #Predicate<PMsg> { $0.deliveryStatusAggregateRaw == value }
        }
    }

    public static func msgs(
        conID: String,
        date: Date,
        comparison: PredicateExpressions.ComparisonOperator
    ) -> Predicate<PMsg> {
        Predicate<PMsg> {
            PredicateExpressions.build_Conjunction(
                lhs: PredicateExpressions.build_Equal(
                    lhs: PredicateExpressions.build_KeyPath(
                        root: PredicateExpressions.build_Arg($0),
                        keyPath: \.conID
                    ),
                    rhs: PredicateExpressions.build_Arg(conID)
                ),
                rhs: PredicateExpressions.build_Comparison(
                    lhs: PredicateExpressions.build_KeyPath(
                        root: PredicateExpressions.build_Arg($0),
                        keyPath: \.date
                    ),
                    rhs: PredicateExpressions.build_Arg(date),
                    op: comparison
                )
            )
        }
    }
}
