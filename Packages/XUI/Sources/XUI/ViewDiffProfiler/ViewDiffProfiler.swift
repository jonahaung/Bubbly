//
//  ViewDiffProfiler.swift
//  XUI
//
//  Created by Aung Ko Min on 11/3/26.
//


//
//  ViewDiffProfiler.swift
//  Conversation
//
//  Created by Aung Ko Min on 11/3/26.
//


import SwiftUI
import Combine


public extension ShapeStyle where Self == Color {
	static var random: Color {
		Color(
			red: .random(in: 0...1),
			green: .random(in: 0...1),
			blue: .random(in: 0...1)
		)
	}
}
// MARK: - Diff Profiler Core

@Observable
public final class ViewDiffProfiler: @unchecked Sendable {
	@MainActor public static let shared = ViewDiffProfiler()
    
	public var isEnabled = false
	public var showOverlay = true
	public var slowViewThreshold: TimeInterval = 0.004 // 4ms
    
	private(set) var viewStats: [String: ViewRenderStats] = [:]
	private(set) var slowViews: [String] = []
    
    private let renderQueue = DispatchQueue(label: "view-diff-profiler")
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupStatsCleanup()
    }
    
    private func setupStatsCleanup() {
        Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.cleanupOldStats()
            }
            .store(in: &cancellables)
    }
    
    private func cleanupOldStats() {
        renderQueue.async { [weak self] in
            let fiveMinutesAgo = Date().addingTimeInterval(-300)
            self?.viewStats = self?.viewStats.filter { $0.value.lastUpdated > fiveMinutesAgo } ?? [:]
        }
    }
    
    func trackRender(viewId: String, duration: TimeInterval) {
        guard isEnabled else { return }
        
        renderQueue.async { [weak self] in
            var stats = self?.viewStats[viewId] ?? ViewRenderStats(viewId: viewId)
            stats.addRender(duration: duration)
            
            DispatchQueue.main.async {
                self?.viewStats[viewId] = stats
                self?.updateSlowViews()
            }
        }
    }
    
    private func updateSlowViews() {
        slowViews = viewStats.values
            .filter { $0.averageDuration > slowViewThreshold }
            .sorted { $0.averageDuration > $1.averageDuration }
            .map { $0.viewId }
    }
    
    func resetStats() {
        viewStats.removeAll()
        slowViews.removeAll()
    }
}

public struct ViewRenderStats {
    public let viewId: String
    public private(set) var renderCount: Int = 0
    public private(set) var totalDuration: TimeInterval = 0
    public private(set) var averageDuration: TimeInterval = 0
    public private(set) var maxDuration: TimeInterval = 0
    public private(set) var lastUpdated = Date()
    public private(set) var recentDurations: [TimeInterval] = []
    
    fileprivate init(viewId: String) {
        self.viewId = viewId
    }
    
    fileprivate mutating func addRender(duration: TimeInterval) {
        renderCount += 1
        totalDuration += duration
        averageDuration = totalDuration / Double(renderCount)
        maxDuration = max(maxDuration, duration)
        lastUpdated = Date()
        
        recentDurations.append(duration)
        if recentDurations.count > 10 {
            recentDurations.removeFirst()
        }
    }
}

// MARK: - View Modifier

public struct ViewDiffProfilerModifier: ViewModifier {
    let viewId: String
    @State private var profiler = ViewDiffProfiler.shared
    @State private var renderStartTime: CFAbsoluteTime?
    @State private var lastRenderDuration: TimeInterval?
    
    public func body(content: Content) -> some View {
        content
            .overlay(alignment: .topTrailing) {
                if profiler.isEnabled && profiler.showOverlay {
                    DiffProfilerBadge(
                        viewId: viewId,
                        duration: lastRenderDuration ?? 0,
                        isSlow: (lastRenderDuration ?? 0) > profiler.slowViewThreshold
                    )
                }
            }
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            renderStartTime = CFAbsoluteTimeGetCurrent()
                        }
                        .onChange(of: geometry.size) { _, _ in
                            recordRender()
                        }
                        .onChange(of: geometry.frame(in: .global)) { _, _ in
                            recordRender()
                        }
                }
            )
            .onAppear {
                renderStartTime = CFAbsoluteTimeGetCurrent()
            }
            .onDisappear {
                renderStartTime = nil
            }
    }
    
    private func recordRender() {
        guard let startTime = renderStartTime else {
            renderStartTime = CFAbsoluteTimeGetCurrent()
            return
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        lastRenderDuration = duration
        
        profiler.trackRender(viewId: viewId, duration: duration)
        
        // Reset timer for next render
        renderStartTime = CFAbsoluteTimeGetCurrent()
    }
}

public extension View {
    func trackRendering(_ viewId: String) -> some View {
        modifier(ViewDiffProfilerModifier(viewId: viewId))
    }
}

// MARK: - Overlay Components

struct DiffProfilerBadge: View {
    let viewId: String
    let duration: TimeInterval
    let isSlow: Bool
    
    var durationString: String {
        if duration < 0.001 {
            return String(format: "%.1fµs", duration * 1_000_000)
        } else if duration < 0.1 {
            return String(format: "%.2fms", duration * 1000)
        } else {
            return String(format: "%.1fms", duration * 1000)
        }
    }
    
    var body: some View {
        Text("\(viewId)\n\(durationString)")
            .font(.system(size: 8, weight: .medium, design: .monospaced))
            .multilineTextAlignment(.center)
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(backgroundColor)
                    .shadow(color: .black.opacity(0.2), radius: 2)
            )
            .foregroundColor(.white)
            .padding(4)
    }
    
    var backgroundColor: Color {
        if isSlow {
            return .red.opacity(0.8)
        } else if duration > 0.002 {
            return .orange.opacity(0.8)
        } else {
            return .blue.opacity(0.6)
        }
    }
}

// MARK: - Profiler Control Panel

public struct DiffProfilerPanel: View {
    @State private var profiler = ViewDiffProfiler.shared
    @State private var selectedTab = 0
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "gauge.medium")
                Text("View Diff Profiler")
                    .font(.headline)
                Spacer()
                Toggle("Enabled", isOn: $profiler.isEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
            }
            .padding()
            .background(Color(.systemBackground))
            
            // Tabs
            Picker("", selection: $selectedTab) {
                Text("Live Views").tag(0)
                Text("Slow Views").tag(1)
                Text("Statistics").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            Divider()
            
            // Content
            ScrollView {
                switch selectedTab {
                case 0:
                    LiveViewsList()
                case 1:
                    SlowViewsList()
                case 2:
                    StatisticsView()
                default:
                    EmptyView()
                }
            }
            
            Divider()
            
            // Footer
            HStack {
                Button("Reset Stats") {
                    profiler.resetStats()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Toggle("Overlay", isOn: $profiler.showOverlay)
                    .toggleStyle(SwitchToggleStyle(tint: .green))
                
                Slider(value: $profiler.slowViewThreshold, in: 0.001...0.020) {
                    Text("Threshold")
                } minimumValueLabel: {
                    Text("1ms")
                } maximumValueLabel: {
                    Text("20ms")
                }
                .frame(width: 150)
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .frame(width: 400, height: 500)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(radius: 10)
    }
}

struct LiveViewsList: View {
    @State private var profiler = ViewDiffProfiler.shared
    
    var body: some View {
        LazyVStack(spacing: 8) {
            ForEach(Array(profiler.viewStats.values.sorted { $0.lastUpdated > $1.lastUpdated }), id: \.viewId) { stats in
                ViewStatRow(stats: stats)
            }
        }
        .padding()
    }
}

struct SlowViewsList: View {
    @State private var profiler = ViewDiffProfiler.shared
    
    var body: some View {
        if profiler.slowViews.isEmpty {
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
                Text("No slow views detected")
                    .font(.headline)
                Text("Threshold: \(Int(profiler.slowViewThreshold * 1000))ms")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 200)
        } else {
            LazyVStack(spacing: 8) {
                ForEach(profiler.slowViews, id: \.self) { viewId in
                    if let stats = profiler.viewStats[viewId] {
                        SlowViewRow(stats: stats, threshold: profiler.slowViewThreshold)
                    }
                }
            }
            .padding()
        }
    }
}

struct StatisticsView: View {
    @State private var profiler = ViewDiffProfiler.shared
    
    var totalRenders: Int {
        profiler.viewStats.values.reduce(0) { $0 + $1.renderCount }
    }
    
    var averageRenderTime: TimeInterval {
        let total = profiler.viewStats.values.reduce(0) { $0 + $1.totalDuration }
        return totalRenders > 0 ? total / Double(totalRenders) : 0
    }
    
    var maxRenderTime: TimeInterval {
        profiler.viewStats.values.map { $0.maxDuration }.max() ?? 0
    }
    
    var body: some View {
        VStack(spacing: 16) {
            StatCard(title: "Total Renders", value: "\(totalRenders)")
            StatCard(title: "Avg Render Time", value: String(format: "%.3fms", averageRenderTime * 1000))
            StatCard(title: "Max Render Time", value: String(format: "%.3fms", maxRenderTime * 1000))
            StatCard(title: "Unique Views", value: "\(profiler.viewStats.count)")
            
            Divider()
            
            HStack {
                Text("Render Distribution")
                    .font(.headline)
                Spacer()
            }
            
            ForEach(Array(profiler.viewStats.values.prefix(5)), id: \.viewId) { stats in
                HStack {
                    Text(stats.viewId)
                        .font(.caption)
                        .lineLimit(1)
                    Spacer()
                    Text("\(stats.renderCount)x")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2fms", stats.averageDuration * 1000))
                        .font(.caption.bold())
                        .foregroundColor(stats.averageDuration > profiler.slowViewThreshold ? .red : .primary)
                }
            }
        }
        .padding()
    }
}

struct ViewStatRow: View {
    let stats: ViewRenderStats
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(stats.viewId)
                    .font(.caption.bold())
                    .lineLimit(1)
                
                Text("\(stats.renderCount) renders")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "Avg: %.3fms", stats.averageDuration * 1000))
                    .font(.caption)
                    .foregroundColor(stats.averageDuration > 0.004 ? .red : .primary)
                
                Text(String(format: "Max: %.3fms", stats.maxDuration * 1000))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct SlowViewRow: View {
    let stats: ViewRenderStats
    let threshold: TimeInterval
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(stats.viewId)
                    .font(.caption.bold())
                
                Text("\(stats.renderCount) renders")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.3fms", stats.averageDuration * 1000))
                    .font(.caption.bold())
                    .foregroundColor(.red)
                
                Text("threshold: \(Int(threshold * 1000))ms")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2.bold())
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Example Usage

struct ContentView: View {
    @State private var counter = 0
    @State private var showProfiler = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Track specific views
            ExpensiveView(counter: counter)
                .trackRendering("ExpensiveView")
            
            ListView(counter: counter)
                .trackRendering("ListView")
            
            Button("Increment Counter: \(counter)") {
                counter += 1
            }
            .trackRendering("Button")
            
            Button("Toggle Profiler") {
                showProfiler.toggle()
            }
            .trackRendering("ToggleButton")
        }
        .padding()
        .sheet(isPresented: $showProfiler) {
            DiffProfilerPanel()
        }
    }
}

struct ExpensiveView: View {
    let counter: Int
    
    var body: some View {
        VStack {
            Text("Expensive Computation")
            // Simulate expensive rendering
            let _ = (0..<1000).reduce(0, +)
            Text("Result: \(counter * 1000)")
        }
        .padding()
        .background(Color.blue.opacity(0.2))
        .cornerRadius(8)
    }
}

struct ListView: View {
    let counter: Int
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("List Items")
                .font(.headline)
            
            ForEach(0..<3, id: \.self) { index in
                Text("Item \(index + 1): \(counter + index)")
                    .padding(.leading)
            }
        }
        .padding()
        .background(Color.green.opacity(0.2))
        .cornerRadius(8)
    }
}
