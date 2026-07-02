//  TimingCurves.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

public extension Animation {
    /// A timing curve that anticipates animating to the target.
    static var anticipate: Animation {
        anticipate(duration: 0.35)
    }

    /// A timing curve that anticipates animating to the target.
    static func anticipate(duration: Double) -> Animation {
        .timingCurve(0.33, 0, 0.66, -0.65, duration: duration)
    }

    /// A timing curve that overshoots the target.
    static var overshoot: Animation {
        overshoot(duration: 0.35)
    }

    /// A timing curve that overshoots the target.
    static func overshoot(duration: Double) -> Animation {
        .timingCurve(0.33, 1.55, 0.66, 1, duration: duration)
    }

    /// A timing curve that anticipates animating to the target and overshoots
    /// it.
    static var anticipateOvershoot: Animation {
        anticipateOvershoot(duration: 0.35)
    }

    /// A timing curve that anticipates animating to the target and overshoots
    /// it.
    static func anticipateOvershoot(duration: Double) -> Animation {
        .timingCurve(0.66, -0.55, 0.33, 1.6, duration: duration)
    }
}

public extension Animation {

    /// Aggressive start → ultra smooth middle → ultra smooth finish
    static var ultraSmoothPower: Animation {
        ultraSmoothPower(duration: 0.45)
    }

    static func ultraSmoothPower(duration: Double) -> Animation {
        .timingCurve(0.15, 0.9, 0.25, 1.0, duration: duration)
    }

    static func ultraSmoothAggressive(duration: Double) -> Animation {
        .timingCurve(0.05, 1.0, 0.2, 1.0, duration: duration)
    }

    /// Fast start → smooth cruise → soft landing (very natural)
    static func fluidNatural(duration: Double = 0.4) -> Animation {
        .timingCurve(0.2, 0.8, 0.2, 1.0, duration: duration)
    }

    /// Extremely soft and premium feel (Apple-like)
    static func premiumSmooth(duration: Double = 0.5) -> Animation {
        .timingCurve(0.25, 0.9, 0.3, 1.0, duration: duration)
    }

    /// Snappy start → long glide → subtle stop (great for chat)
    static func chatSnap(duration: Double = 0.35) -> Animation {
        .timingCurve(0.1, 1.0, 0.2, 1.0, duration: duration)
    }

    /// Gentle ease with long tail (for fades / opacity)
    static func softFade(duration: Double = 0.6) -> Animation {
        .timingCurve(0.3, 0.7, 0.4, 1.0, duration: duration)
    }

    /// Sharp interaction feedback (tap, press)
    static func interactionSnap(duration: Double = 0.2) -> Animation {
        .timingCurve(0.2, 1.2, 0.3, 1.0, duration: duration)
    }
}

public extension Animation {
    static var easeInExponential: Animation {
        easeInExponential(duration: 0.35)
    }

    static func easeInExponential(duration: Double) -> Animation {
        .timingCurve(0.95, 0.05, 0.795, 0.035, duration: duration)
    }

    static var easeOutExponential: Animation {
        easeOutExponential(duration: 0.35)
    }

    static func easeOutExponential(duration: Double) -> Animation {
        .timingCurve(0.19, 1, 0.22, 1, duration: duration)
    }

    static var easeInOutExponential: Animation {
        easeInOutExponential(duration: 0.35)
    }

    static func easeInOutExponential(duration: Double) -> Animation {
        .timingCurve(1, 0, 0, 1, duration: duration)
    }

    static var linearSmooth: Animation {
        linearSmooth(duration: 0.5)
    }

    static func linearSmooth(duration: Double) -> Animation {
        .timingCurve(0, 0, 0, 1.01, duration: duration)
    }
}
