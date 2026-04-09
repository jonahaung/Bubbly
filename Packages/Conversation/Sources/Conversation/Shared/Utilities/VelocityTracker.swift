// © 2026 Aung Ko Min

#if os(iOS)
//
    // Copyright © 2026 Aung Ko Min. All rights reserved.
//

    import CoreGraphics
    import QuartzCore

    struct VelocityTracker {
        private(set) var velocity: CGFloat = 0

        private var lastValue: CGFloat = 0
        private var lastTimestamp: CFTimeInterval = 0

        mutating func update(value: CGFloat) {
            let now = CACurrentMediaTime()

            defer {
                lastValue = value
                lastTimestamp = now
            }

            guard lastTimestamp != 0 else {
                return
            }

            let deltaValue = value - lastValue
            let deltaTime = now - lastTimestamp
            guard deltaTime > 0 else {
                return
            }

            let rawVelocity = deltaValue / CGFloat(deltaTime)
            velocity = velocity * 0.85 + rawVelocity * 0.15
        }
    }

#endif
