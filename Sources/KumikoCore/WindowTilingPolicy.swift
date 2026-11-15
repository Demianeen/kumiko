import Foundation

public struct WindowResizeAxes: Codable, Equatable, Sendable {
	public var width: Bool
	public var height: Bool

	public init(width: Bool, height: Bool) {
		self.width = width
		self.height = height
	}

	public var isResizable: Bool { width && height }
}

public struct WindowTilingPolicy {
	private let config: Config.WM

	public init(_ config: Config.WM) {
		self.config = config
	}

	public func canTile(_ window: WindowInfo) -> Bool {
		!window.isResizePending && restriction(window) == nil
	}

	public func isManaged(
		app: String, title: String, identifier: String? = nil, isResizable: Bool = true, subrole: String?,
		fallback: Bool? = nil
	) -> Bool {
		guard subrole == "AXStandardWindow", !config.floatFixedSize || isResizable,
		      !config.floatSettings || !Self.isSettings(title: title, identifier: identifier)
		else { return false }
		return wantsTiling(app: app, title: title, identifier: identifier, fallback: fallback)
	}

	public static func isSettings(title: String, identifier: String?) -> Bool {
		let words = ["settings", "preferences"]
		if let identifier = identifier?.lowercased(), words.contains(where: identifier.contains) { return true }
		return words.contains(title.lowercased())
	}

	public func warnings(for rule: WindowRule, windows: [WindowInfo]) -> [String] {
		guard config.useRules, rule.manage else { return [] }
		return warnings(windows.filter { matches(rule, app: $0.app, title: $0.title, identifier: $0.identifier) })
	}

	public func warnings(forApp app: String, windows: [WindowInfo]) -> [String] {
		warnings(windows.filter {
			$0.app == app && wantsTiling(app: $0.app, title: $0.title, identifier: $0.identifier)
		})
	}

	public func workspaceWarnings(forApp app: String, isPattern: Bool, windows: [WindowInfo]) -> [String] {
		let selected = windows.filter { isPattern ? matches(app, $0.app, whole: true) : $0.app == app }
		return selected.sorted { $0.id < $1.id }.compactMap { window in
			guard !window.isResizePending else { return nil }
			let reason = restriction(window)
				?? (wantsTiling(app: window.app, title: window.title, identifier: window.identifier)
					? nil : "Window Rules sets it to Float.")
			guard let reason else { return nil }
			return "\(label(window)): \(reason) It can still open on this workspace."
		}
	}

	private func warnings(_ windows: [WindowInfo]) -> [String] {
		windows.sorted { $0.id < $1.id }.compactMap { window in
			guard !window.isResizePending, let reason = restriction(window) else { return nil }
			return "\(label(window)): \(reason) This window will stay floating."
		}
	}

	private func label(_ window: WindowInfo) -> String {
		window.title.isEmpty ? (window.identifier ?? window.app) : window.title
	}

	private func restriction(_ window: WindowInfo) -> String? {
		if window.subrole != "AXStandardWindow" { return "Dialogs and panels cannot be tiled." }
		if config.floatFixedSize && !window.isResizable {
			if let axes = window.resizeAxes {
				if !axes.width && axes.height { return "Its width is fixed." }
				if axes.width && !axes.height { return "Its height is fixed." }
			}
			return "Its size is fixed."
		}
		if config.floatSettings && Self.isSettings(title: window.title, identifier: window.identifier) {
			return "Float settings windows is enabled."
		}
		return nil
	}

	private func wantsTiling(app: String, title: String, identifier: String?, fallback: Bool? = nil) -> Bool {
		var manage = fallback ?? config.manage
		for rule in config.rules where config.useRules && matches(rule, app: app, title: title, identifier: identifier) {
			manage = rule.manage
		}
		return manage
	}

	private func matches(_ rule: WindowRule, app: String, title: String, identifier: String?) -> Bool {
		matches(rule.app, app, whole: true) && matches(rule.title, title) && matches(rule.id, identifier ?? "")
	}

	private func matches(_ pattern: String?, _ text: String, whole: Bool = false) -> Bool {
		guard let pattern else { return true }
		let expression = whole ? "^(?:\(pattern))$" : pattern
		guard let regex = try? NSRegularExpression(pattern: expression) else { return false }
		return regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
	}
}
