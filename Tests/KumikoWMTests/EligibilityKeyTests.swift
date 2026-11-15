import KumikoCore
@testable import KumikoWM
import Testing

struct EligibilityKeyTests {
	@MainActor @Test func protectionChangesReconcileAManualTilingOverride() {
		let policy = WindowTilingPolicy(Config.WM(manage: false))
		var window = WindowInfo(
			id: 1, pid: 42, app: "Example", bundleID: nil, title: "Main", subrole: "AXStandardWindow",
			frame: .zero, isMinimized: false, isHidden: false, isFullscreen: false, isManaged: false
		)
		let before = WindowManager.EligibilityKey(window, tiling: policy)
		window.title = "Settings"
		#expect(before != WindowManager.EligibilityKey(window, tiling: policy))
		window.title = "Main"
		window.identifier = "preferences"
		#expect(before != WindowManager.EligibilityKey(window, tiling: policy))
		window.identifier = nil
		window.subrole = "AXDialog"
		#expect(before != WindowManager.EligibilityKey(window, tiling: policy))
	}
}
