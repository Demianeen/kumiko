import KumikoCore
import Foundation
import Testing

struct WindowTilingPolicyTests {
	private func window(_ axes: WindowResizeAxes?, title: String = "Main", subrole: String = "AXStandardWindow") -> WindowInfo {
		WindowInfo(
			id: 1, pid: 42, app: "Example", bundleID: nil, title: title, subrole: subrole,
			frame: .zero, isMinimized: false, isHidden: false, isFullscreen: false, isManaged: false,
			isResizable: axes?.isResizable ?? true, resizeAxes: axes
		)
	}

	@Test func fixedAxisCannotBeForcedIntoTile() {
		let policy = WindowTilingPolicy(.init())
		for axes in [WindowResizeAxes(width: false, height: true), WindowResizeAxes(width: true, height: false)] {
			#expect(!policy.canTile(window(axes)))
		}
		#expect(policy.canTile(window(WindowResizeAxes(width: true, height: true))))
	}

	@Test func fixedAxisPreferenceCanBeDisabled() {
		var config = Config.WM()
		config.floatFixedSize = false
		#expect(WindowTilingPolicy(config).canTile(window(WindowResizeAxes(width: false, height: true))))
	}

	@Test func warningsMatchWindowFilters() {
		let policy = WindowTilingPolicy(.init())
		let windows = [window(WindowResizeAxes(width: false, height: true))]
		#expect(policy.warnings(for: WindowRule(app: "Example", manage: true), windows: windows).count == 1)
		#expect(policy.warnings(for: WindowRule(app: "Other", manage: true), windows: windows).isEmpty)
		#expect(policy.warnings(for: WindowRule(app: "Example", title: "Other", manage: true), windows: windows).isEmpty)
		#expect(policy.warnings(for: WindowRule(app: "Example", manage: false), windows: windows).isEmpty)
		#expect(policy.warnings(for: WindowRule(app: "Example", id: "Other", manage: true), windows: windows).isEmpty)
	}

	@Test func warningsRespectExceptionsAndPendingChecks() {
		var config = Config.WM()
		config.rules = [WindowRule(app: "Example", manage: true), WindowRule(app: "Example", title: "Main", manage: false)]
		let policy = WindowTilingPolicy(config)
		#expect(policy.warnings(forApp: "Example", windows: [window(WindowResizeAxes(width: false, height: true))]).isEmpty)
		var pending = window(nil)
		pending.isResizePending = true
		#expect(!policy.canTile(pending))
		#expect(policy.warnings(for: WindowRule(app: "Example", manage: true), windows: [pending]).isEmpty)
	}

	@Test func workspaceWarningsMatchPatternsAndExplainRouting() {
		let policy = WindowTilingPolicy(.init())
		let windows = [window(WindowResizeAxes(width: true, height: false))]
		let warnings = policy.workspaceWarnings(forApp: "Ex.*", isPattern: true, windows: windows)
		#expect(warnings.count == 1)
		#expect(warnings.first?.contains("workspace") == true)
		#expect(policy.workspaceWarnings(forApp: "Other", isPattern: false, windows: windows).isEmpty)
		#expect(policy.workspaceWarnings(forApp: "Example", isPattern: false, windows: []).isEmpty)
	}

	@Test func olderWindowJSONStillDecodes() throws {
		let encoded = try JSONEncoder().encode(window(nil))
		var object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
		object.removeValue(forKey: "resizeAxes")
		object.removeValue(forKey: "isResizePending")
		let decoded = try JSONDecoder().decode(WindowInfo.self, from: JSONSerialization.data(withJSONObject: object))
		#expect(decoded.resizeAxes == nil)
		#expect(!decoded.isResizePending)
	}
}
