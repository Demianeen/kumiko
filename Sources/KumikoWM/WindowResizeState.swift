import CoreGraphics
import KumikoCore

struct WindowResizeState {
	var axes: WindowResizeAxes?
	private(set) var needsCheck = false
	private var settable: Bool?
	private var title: String?
	private var identifier: String?
	private var rejectedSize: CGSize?

	mutating func rejected(_ requested: CGSize, actual: CGSize) -> Bool {
		guard axes?.isResizable == true, requested != rejectedSize,
		      abs(requested.width - actual.width) > 1 || abs(requested.height - actual.height) > 1
		else { return false }
		rejectedSize = requested
		needsCheck = true
		return true
	}

	mutating func record(_ measured: WindowResizeAxes?) {
		if let measured {
			axes = measured
			needsCheck = false
		}
	}

	mutating func update(
		settable current: Bool?, title: String, identifier: String?, previous: CGSize?, size: CGSize
	) {
		if let current, let settable, current != settable { axes = nil; rejectedSize = nil }
		if axes?.isResizable != true, let oldTitle = self.title, oldTitle != title || self.identifier != identifier {
			axes = nil
			rejectedSize = nil
		}
		self.title = title
		self.identifier = identifier
		if let current { settable = current }
		if current == false {
			axes = WindowResizeAxes(width: false, height: false)
		} else if var measured = axes, let previous {
			if abs(size.width - previous.width) > 0.5 { measured.width = true }
			if abs(size.height - previous.height) > 0.5 { measured.height = true }
			axes = measured
		}
	}
}
