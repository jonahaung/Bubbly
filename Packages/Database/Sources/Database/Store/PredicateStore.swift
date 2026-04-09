// © 2026 Aung Ko Min

import Core
import Foundation
import SwiftData
import XUI

public extension Predicate<PMsg> {
    static func deliveryStatusComparison(
        conID: String,
        currentUserID: String,
        recipient: MsgRecipient,
        deliveryStatus: DeliveryStatus,
        comparison: PredicateExpressions.ComparisonOperator,
    ) -> Predicate<PMsg> {
        let status = deliveryStatus.rawValue
        switch recipient {
        case .outgoing:
            return Predicate<PMsg> { msg in
                PredicateExpressions.Conjunction(
                    lhs: PredicateExpressions.build_Conjunction(
                        lhs: PredicateExpressions.build_Equal(
                            lhs: PredicateExpressions.build_KeyPath(
                                root: PredicateExpressions.build_Arg(msg),
                                keyPath: \.conID,
                            ),
                            rhs: PredicateExpressions.build_Arg(conID),
                        ),
                        rhs: PredicateExpressions.build_Equal(
                            lhs: PredicateExpressions.build_KeyPath(
                                root: PredicateExpressions.build_Arg(msg),
                                keyPath: \.senderID,
                            ),
                            rhs: PredicateExpressions.build_Arg(currentUserID),
                        ),
                    ),
                    rhs: PredicateExpressions.build_Comparison(
                        lhs: PredicateExpressions.build_KeyPath(
                            root: PredicateExpressions.build_Arg(msg),
                            keyPath: \.deliveryStatus,
                        ),
                        rhs: PredicateExpressions.build_Arg(status),
                        op: comparison,
                    ),
                )
            }
        case .incoming:
            return Predicate<PMsg> { msg in
                PredicateExpressions.Conjunction(
                    lhs: PredicateExpressions.build_Conjunction(
                        lhs: PredicateExpressions.build_Equal(
                            lhs: PredicateExpressions.build_KeyPath(
                                root: PredicateExpressions.build_Arg(msg),
                                keyPath: \.conID,
                            ),
                            rhs: PredicateExpressions.build_Arg(conID),
                        ),
                        rhs: PredicateExpressions.build_NotEqual(
                            lhs: PredicateExpressions.build_KeyPath(
                                root: PredicateExpressions.build_Arg(msg),
                                keyPath: \.senderID,
                            ),
                            rhs: PredicateExpressions.build_Arg(currentUserID),
                        ),
                    ),
                    rhs: PredicateExpressions.build_Comparison(
                        lhs: PredicateExpressions.build_KeyPath(
                            root: PredicateExpressions.build_Arg(msg),
                            keyPath: \.deliveryStatus,
                        ),
                        rhs: PredicateExpressions.build_Arg(status),
                        op: comparison,
                    ),
                )
            }
        }
    }

    static func deliveryStatusEqual(
        conID: String,
        currentUserID: String,
        recipient: MsgRecipient,
        deliveryStatus: DeliveryStatus,
    ) -> Predicate<PMsg> {
        let status = deliveryStatus.rawValue
        switch recipient {
        case .outgoing:
            return Predicate<PMsg> { msg in
                PredicateExpressions.Conjunction(
                    lhs: PredicateExpressions.build_Conjunction(
                        lhs: PredicateExpressions.build_Equal(
                            lhs: PredicateExpressions.build_KeyPath(
                                root: PredicateExpressions.build_Arg(msg),
                                keyPath: \.conID,
                            ),
                            rhs: PredicateExpressions.build_Arg(conID),
                        ),
                        rhs: PredicateExpressions.build_Equal(
                            lhs: PredicateExpressions.build_KeyPath(
                                root: PredicateExpressions.build_Arg(msg),
                                keyPath: \.senderID,
                            ),
                            rhs: PredicateExpressions.build_Arg(currentUserID),
                        ),
                    ),
                    rhs: PredicateExpressions.build_Equal(
                        lhs: PredicateExpressions.build_KeyPath(
                            root: PredicateExpressions.build_Arg(msg),
                            keyPath: \.deliveryStatus,
                        ),
                        rhs: PredicateExpressions.build_Arg(status),
                    ),
                )
            }
        case .incoming:
            return Predicate<PMsg> { msg in
                PredicateExpressions.Conjunction(
                    lhs: PredicateExpressions.build_Conjunction(
                        lhs: PredicateExpressions.build_Equal(
                            lhs: PredicateExpressions.build_KeyPath(
                                root: PredicateExpressions.build_Arg(msg),
                                keyPath: \.conID,
                            ),
                            rhs: PredicateExpressions.build_Arg(conID),
                        ),
                        rhs: PredicateExpressions.build_NotEqual(
                            lhs: PredicateExpressions.build_KeyPath(
                                root: PredicateExpressions.build_Arg(msg),
                                keyPath: \.senderID,
                            ),
                            rhs: PredicateExpressions.build_Arg(currentUserID),
                        ),
                    ),
                    rhs: PredicateExpressions.build_Equal(
                        lhs: PredicateExpressions.build_KeyPath(
                            root: PredicateExpressions.build_Arg(msg),
                            keyPath: \.deliveryStatus,
                        ),
                        rhs: PredicateExpressions.build_Arg(status),
                    ),
                )
            }
        }
    }
}

extension Predicate<PMsg> {
    static func conID(_ value: String) -> Predicate<PMsg> {
        #Predicate { $0.conID == value }
    }

    static func notSender(_ value: String) -> Predicate<PMsg> {
        #Predicate { $0.senderID != value }
    }

    static func delivery(
        _ op: PredicateExpressions.ComparisonOperator,
        _ status: DeliveryStatus,
    ) -> Predicate<PMsg> {
        let value = status.rawValue
        switch op {
        case .lessThan: return #Predicate { $0.deliveryStatus < value }
        case .lessThanOrEqual: return #Predicate { $0.deliveryStatus <= value }
        case .greaterThan: return #Predicate { $0.deliveryStatus > value }
        case .greaterThanOrEqual: return #Predicate { $0.deliveryStatus >= value }
        @unknown default:
            return #Predicate { $0.deliveryStatus == value }
        }
    }

    public static func msgs(
        conID: String,
        date: String,
        comparison: PredicateExpressions.ComparisonOperator,
    ) -> Predicate<PMsg> {
        Predicate<PMsg> {
            PredicateExpressions.build_Conjunction(
                lhs: PredicateExpressions.build_Equal(
                    lhs: PredicateExpressions.build_KeyPath(
                        root: PredicateExpressions.build_Arg($0),
                        keyPath: \.conID,
                    ),
                    rhs: PredicateExpressions.build_Arg(conID),
                ),
                rhs: PredicateExpressions.build_Comparison(
                    lhs: PredicateExpressions.build_KeyPath(
                        root: PredicateExpressions.build_Arg($0),
                        keyPath: \.date,
                    ),
                    rhs: PredicateExpressions.build_Arg(date),
                    op: comparison,
                ),
            )
        }
    }
}
