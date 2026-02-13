import SwiftUI

struct FontNamePicker: View {
	@Binding var selectedFontName: String

	var familyName: String
	var fonts: [String]
	var dismissParent: () -> Void

	@State private var searchQuery: String = ""
	@Environment(\.dismiss) private var dismiss
	@Environment(\.textSize) var textSize

	var body: some View {
		let pairs = fonts.map { ($0, $0.fontFace) }
		let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
		let filtered = trimmed.isEmpty ? pairs : pairs
			.filter { $0.1.localizedCaseInsensitiveContains(trimmed) }

		List {
			Section(header: Text(familyName)) {
				ForEach(filtered.indices, id: \.self) { index in
					let (fontName, fontFace) = filtered[index]
					let font = Font.custom(
						UIFont
							.fontNames(forFamilyName: familyName)[index], size: textSize
					)
					HStack {
						Button {
							selectedFontName = fontName
							dismiss()
							dismissParent()
						} label: {
							HStack {
								Text(fontFace)
								Spacer()
							}
						}
						.foregroundStyle(.black.opacity(0.9))
						.buttonStyle(.plain)

						SystemImage(.infoCircle)
							.presentSheet {
								VStack {
									Text(Lorem.paragraph)
										.lineLimit(nil)
										.multilineTextAlignment(.leading)
								}
								.padding()
								.font(font)
							}
					}
					.font(font)
				}
			}
		}
		.environment(\.defaultMinListRowHeight, 48)
		.navigationTitle("Select Style")
		.navigationBarTitleDisplayMode(.inline)
		.searchable(text: $searchQuery, placement: .navigationBarDrawer(displayMode: .always))
	}
}
