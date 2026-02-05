//
//  OnboardingView.swift
//  HomeForYou
//
//  Created by Aung Ko Min on 24/4/23.
//

import SwiftUI
//
// public enum Onboarding {
//    static let key = "com.jonahaung.hasShownOnboarding"
//    public static var hasShown: Bool {
//        get {
//            UserDefaults.standard.bool(forKey: key)
//        }
//        set {
//            UserDefaults.standard.setValue(newValue, forKey: key)
//        }
//    }
// }
//
// public struct OnboardingItem: Identifiable, Hashable {
//    public let id = UUID()
//    public let title: String
//    public let subtitle: String
//    public let imageName: String
//
//    public init(title: String, subtitle: String, imageName: String) {
//        self.title = title
//        self.subtitle = subtitle
//        self.imageName = imageName
//    }
// }
//
// @available(iOS 18.0, *)
// public struct OnboardingView: View {
//	@State private var selection: OnboardingItem.ID
//    private let items: [OnboardingItem]
//    private let onClose: (() -> Void)?
//    @Environment(\.dismiss) private var dismiss
//
//    public init(items: [OnboardingItem], _ onClose: (() -> Void)? = nil) {
//        self.items = items
//        self.onClose = onClose
//    }
//
//    public var body: some View {
//        TabView(selection: $selection) {
//            ForEach(0 ..< items.count, id: \.self) { i in
//                if let item = items[safe: i] {
//                    OnboardingCell(item: item, index: i)
//                        .tag(i)
//                }
//            }
//        }
//        .animation(.snappy, value: selection)
//        .overlay(overlayView)
//        .tabViewStyle(.page(indexDisplayMode: .never))
//        .ignoresSafeArea(edges: .all)
//        .statusBarHidden(true)
//    }
//
//    private var overlayView: some View {
//        VStack {
//            HStack {
//                Spacer()
//                if hasNext {
//                    Button {
//                        skip()
//                    } label: {
//                        Text("Skip")
//                            .padding()
//                    }
//                }
//            }
//            Spacer()
//            HStack {
//                if hasNext {
//					XPhotoPageControl<OnboardingItem>(
//						selection: $selection,
//						items: items,
//						size: 13
//					)
//                        .foregroundStyle(.secondary)
//                    Spacer()
//                    Button {
//                        next()
//                    } label: {
//                        SystemImage(.arrowshapeRightFill, 30)
//                            .padding()
//                    }
//                    .phaseAnimation([.scale(0.9), .scale(1.5)], selection.description)
//                } else {
//                    let hasShownOnboarding = Onboarding.hasShown
//                    Button {
//                        Onboarding.hasShown = true
//                        dismiss()
//                        onClose?()
//                    } label: {
//                        Text(hasShownOnboarding ? "Close" : "Done & Continue")
//                            ._borderedProminentButtonStyle()
//                    }
//                    .padding()
//                }
//            }
//        }
//        .padding()
//    }
//
//    private var hasNext: Bool { selection + 1 < items.count }
//    private var hasPrevious: Bool { selection > 0 }
//
//    private func next() {
//        if hasNext {
//            selection += 1
//        }
//    }
//
//    private func previous() {
//        if hasPrevious {
//            selection -= 1
//        }
//    }
//
//    private func skip() {
//        if hasNext {
//            selection = items.count - 1
//        }
//    }
// }
//
// @available(iOS 18.0, *)
// private struct OnboardingCell: View {
//    let item: OnboardingItem
//    let index: Int
//
//    var body: some View {
//        GeometryReader { geo in
//            let height = geo.size.height / 2
//            StretchyHeaderScrollView(headerHeight: height, multipliter: 1) {
//                VStack(alignment: .leading) {
//                    ZStack {
//                        Color.clear
//                    }
//                    .frame(height: height)
//                    Text(item.title)
//                        .font(.title)
//                    Text(item.subtitle)
//                        .font(.body)
//                    Spacer(minLength: 100)
//                }
//                .padding()
//            } header: {
//                Image(item.imageName)
//                    .resizable()
//                    .scaledToFill()
//                    .frame(height: height)
//                    .ignoresSafeArea()
//            }
//            .ignoresSafeArea()
//        }
//    }
// }
