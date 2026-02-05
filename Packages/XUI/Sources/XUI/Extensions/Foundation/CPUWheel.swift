//
//  CPUWheel.swift
//  SGSwiftUI
//
//  Created by Aung Ko Min on 15/2/25.
//

@preconcurrency import Darwin
import SwiftUI

// public struct CPUWheel: View {
//    @State private var monitor = CPUMonitor()
//
//    private let gradient = AngularGradient(
//        colors: [.green, .yellow, .red],
//        center: .center
//    )
//
//    public init() {}
//
//    public var body: some View {
//        Circle()
//            .strokeBorder(lineWidth: 1)
//            .foregroundStyle(.background)
//            .background(
//                Circle()
//                    .fill(gradient)
//                    .clipShape(CPUClip(pct: monitor.cpu))
//            )
//            .shadow(radius: 4)
//            .overlay(
//                CPULabel(pct: Int(monitor.cpu))
//            )
//            .task {
//                for await _ in Timer.publish(every: 0.2, on: .main, in: .common).autoconnect().values {
//                    withAnimation(.easeInOut(duration: 0.2)) {
//                        monitor.update()
//                    }
//                }
//            }
//    }
// }
//
//// MARK: - Label
//
// private struct CPULabel: View {
//    let pct: Int
//    var body: some View {
//        Text("\(pct)%")
//            .font(.caption2.bold())
//            .foregroundStyle(Color.accentColor)
//            .transaction { $0.animation = nil }
//    }
// }
//
//// MARK: - Shape
//
// private struct CPUClip: Shape {
//    var pct: Double
//
//    var animatableData: Double {
//        get { pct }
//        set { pct = newValue }
//    }
//
//    func path(in rect: CGRect) -> Path {
//        Path { path in
//            let center = CGPoint(x: rect.midX, y: rect.midY)
//            path.move(to: center)
//            path.addArc(
//                center: center,
//                radius: rect.width / 2,
//                startAngle: .degrees(0),
//                endAngle: .degrees((pct / 100) * 360),
//                clockwise: false
//            )
//            path.closeSubpath()
//        }
//    }
// }
//
//// MARK: - CPU Monitor
//
// @MainActor
// @Observable
// private final class CPUMonitor {
//    var cpu: Double = 0
//
//    func update() {
//        cpu = Self.cpuUsage()
//    }
//
//    static func cpuUsage() -> Double {
//        var threadList: thread_act_array_t?
//        var threadCount: mach_msg_type_number_t = 0
//        guard task_threads(mach_task_self_, &threadList, &threadCount) == KERN_SUCCESS,
//              let threadList
//        else {
//            return -1
//        }
//
//        defer {
//            vm_deallocate(
//                mach_task_self_,
//                vm_address_t(bitPattern: threadList),
//                vm_size_t(Int(threadCount) * MemoryLayout<thread_t>.stride)
//            )
//        }
//
//        var totalCpu: Double = 0
//        for index in 0 ..< Int(threadCount) {
//            var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)
//            var thinfo = [integer_t](repeating: 0, count: Int(threadInfoCount))
//            guard thread_info(threadList[index], thread_flavor_t(THREAD_BASIC_INFO), &thinfo, &threadInfoCount) == KERN_SUCCESS else {
//                continue
//            }
//
//            let info = convertThreadInfoToThreadBasicInfo(thinfo)
//            if info.flags != TH_FLAGS_IDLE {
//                totalCpu += (Double(info.cpu_usage) / Double(TH_USAGE_SCALE)) * 100.0
//            }
//        }
//        return totalCpu
//    }
//
//    static func convertThreadInfoToThreadBasicInfo(_ threadInfo: [integer_t]) -> thread_basic_info {
//        thread_basic_info(
//            user_time: time_value_t(seconds: threadInfo[0], microseconds: threadInfo[1]),
//            system_time: time_value_t(seconds: threadInfo[2], microseconds: threadInfo[3]),
//            cpu_usage: threadInfo[4],
//            policy: threadInfo[5],
//            run_state: threadInfo[6],
//            flags: threadInfo[7],
//            suspend_count: threadInfo[8],
//            sleep_time: threadInfo[9]
//        )
//    }
// }
