//  Haptics.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

#if os(iOS)
    import CoreHaptics

    @MainActor
    struct Haptics {
        private static let engine: CHHapticEngine? = {
            let engine = try? CHHapticEngine()
            addHapticEngineObservers()
            return engine
        }()

        private static func addHapticEngineObservers() {
            // Without stopping the CHHapticEngine when entering background mode, haptics are not played when the app enters the foreground.
            // See https://github.com/EmergeTools/Pow/issues/69
            NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { _ in
                engine?.stop()
            }
            NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { _ in
                try? engine?.start()
            }
        }

        private static let supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics

        private static var counter: Int = 0 {
            didSet {
                guard supportsHaptics else { return }

                if oldValue == 0, counter == 1 {
                    #if DEBUG
                        print("[Pow] Starting haptics engine.")
                    #endif

                    try? engine?.start()
                } else if counter == 0 {
                    #if DEBUG
                        print("[Pow] Stopping haptics engine.")
                    #endif

                    engine?.stop()
                }
            }
        }

        static func acquire() {
            counter += 1
        }

        static func release() {
            counter -= 1
        }

        static func play(_ pattern: CHHapticPattern, at time: TimeInterval = CHHapticTimeImmediate) {
            let player = try? engine?.makePlayer(with: pattern)

            try? player?.start(atTime: time)
        }
    }

    extension View {
        func usesCustomHaptics() -> some View {
            modifier(
                _AppearanceActionModifier {
                    Haptics.acquire()
                } disappear: {
                    Haptics.release()
                }
            )
        }
    }
#else
    extension View {
        func usesCustomHaptics() -> Self {
            self
        }
    }
#endif
