import Core
import Database
import Services
import SwiftUI
import XUI

struct RootNavView: View {
	@Environment(Router.self) private var router

	var body: some View {
		NavigationSplitView {
			SidebarView()
		} detail: {
			router.selectedTab.destination()
		}
		.navigationSplitViewStyle(.automatic)
	}
}

struct SidebarView: View {
	@Environment(Router.self) private var router

	var body: some View {
		List(selection: selection) {
			Section {
				ForEach(TabPath.allCases, id: \.self) { tabPath in
					SidebarRow(tabPath: tabPath, isSelected: router.selectedTab == tabPath) {
						router.selectedTab = tabPath
					}
					.id(tabPath)
				}
			}
		}
		.listStyle(.sidebar)
		.navigationTitle("Bubbley")
	}

	private var selection: Binding<TabPath?> {
		Binding(get: { router.selectedTab }, set: { newValue in
			if let newValue {
				router.selectTab(newValue)
			}
		})
	}
}

private struct SidebarRow: View {
	let tabPath: TabPath
	let isSelected: Bool
	let action: () -> Void

	var body: some View {
		Button(action: action) {
			rowLabel
		}
		.buttonStyle(.borderless)
	}

	@ViewBuilder
	private var rowLabel: some View {
		let name = tabPath.localizedName
		let system = tabPath.systemName
		if isSelected {
			Label(name, systemImage: system)
				.symbolRenderingMode(.multicolor)
				.symbolVariant(.fill)
		} else {
			Label(name, systemImage: system)
				.symbolRenderingMode(.hierarchical)
		}
	}
}
