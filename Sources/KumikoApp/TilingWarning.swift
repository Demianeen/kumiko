import SwiftUI

struct TilingWarning: View {
	let reasons: [String]
	var workspace = false

	var body: some View {
		if !reasons.isEmpty {
			HStack(alignment: .top, spacing: 8) {
				Image(systemName: "exclamationmark.triangle.fill")
					.foregroundStyle(.orange)
					.accessibilityHidden(true)
				VStack(alignment: .leading, spacing: 4) {
					Text("Tiling warnings")
					ForEach(Array(Set(reasons)).sorted(), id: \.self) { reason in
						Text(reason)
					}
					if workspace {
						Text("Layout, stack, and size settings do not apply to these windows. Moving them between workspaces still works.")
					}
				}
				.foregroundStyle(.secondary)
				.fixedSize(horizontal: false, vertical: true)
			}
			.font(.caption)
			.frame(maxWidth: .infinity, alignment: .leading)
			.accessibilityElement(children: .combine)
		}
	}
}
