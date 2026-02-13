import SwiftUI

struct RecentFontsSectionView: View {
	@Binding var selectedFontName: String
	var recentFonts: [String]

	@Environment(\.dismiss) private var dismiss
	@Environment(\.textSize) private var textSize

	var body: some View {
		if !recentFonts.isEmpty {
			Section(header: Text("Recently Used")) {
				ScrollView(.horizontal) {
					HStack {
						ForEach(recentFonts, id: \.self) { recentFont in
							Button {
								selectedFontName = recentFont
								dismiss()
							} label: {
								HStack {
									Text("Aa")
										.font(Font.custom(recentFont, size: textSize))

									Divider()

									Text(recentFont.fontDisplayName)
										.font(.system(size: textSize))
								}
								.padding(12)
								.background(
									RoundedRectangle(cornerRadius: 8)
										.fill(.white.opacity(0.9))
										.stroke(recentFont == selectedFontName ? Color.blue : Color
											.clear)
								)
							}
							.padding(.vertical, 8)
							.padding(.horizontal, 4)
							.buttonStyle(.plain)
						}
					}
				}
				.scrollIndicators(.hidden)
				.listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
			}
			.listRowBackground(Color.clear)
			.listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 0))
		}
	}
}
