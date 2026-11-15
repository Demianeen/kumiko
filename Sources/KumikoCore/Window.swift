import CoreGraphics

/// A window as kumiko sees it: plain data, safe to hand to any module or print as JSON.
public struct WindowInfo: Codable, Equatable, Sendable {
	/// The WindowServer id, stable for the life of the window and the same one other tools show.
	public var id: UInt32
	public var pid: Int32
	public var app: String
	public var bundleID: String?
	public var title: String
	/// `AXStandardWindow` for ordinary windows; dialogs, sheets and panels say something else.
	public var subrole: String?
	/// What the app calls the window (`AXIdentifier`), there when it has no title too.
	public var identifier: String?
	/// Tiling needs both axes: a fixed width or height leaves gaps in the layout.
	public var isResizable: Bool
	public var resizeAxes: WindowResizeAxes?
	public var isResizePending: Bool
	public var frame: CGRect
	public var isMinimized: Bool
	/// The app is hidden (cmd-h), so the window is not on screen though it still exists.
	public var isHidden: Bool
	/// In macOS native full screen: the window has a native Space of its own and is left alone.
	public var isFullscreen: Bool
	public var isManaged: Bool
	/// A native tab behind the one in front. Each tab is a window of its own, but only the one in
	/// front is on screen, and the group takes a single place in the layout.
	public var isBackgroundTab: Bool

	public init(
		id: UInt32, pid: Int32, app: String, bundleID: String?, title: String, subrole: String?,
		frame: CGRect, isMinimized: Bool, isHidden: Bool, isFullscreen: Bool, isManaged: Bool, identifier: String? = nil,
		isResizable: Bool = true, isBackgroundTab: Bool = false, resizeAxes: WindowResizeAxes? = nil,
		isResizePending: Bool = false
	) {
		self.identifier = identifier
		self.isResizable = isResizable
		self.resizeAxes = resizeAxes
		self.isResizePending = isResizePending
		self.isBackgroundTab = isBackgroundTab
		self.id = id
		self.pid = pid
		self.app = app
		self.bundleID = bundleID
		self.title = title
		self.subrole = subrole
		self.frame = frame
		self.isMinimized = isMinimized
		self.isHidden = isHidden
		self.isFullscreen = isFullscreen
		self.isManaged = isManaged
	}

	public init(from decoder: any Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		id = try values.decode(UInt32.self, forKey: .id)
		pid = try values.decode(Int32.self, forKey: .pid)
		app = try values.decode(String.self, forKey: .app)
		bundleID = try values.decodeIfPresent(String.self, forKey: .bundleID)
		title = try values.decode(String.self, forKey: .title)
		subrole = try values.decodeIfPresent(String.self, forKey: .subrole)
		identifier = try values.decodeIfPresent(String.self, forKey: .identifier)
		isResizable = try values.decode(Bool.self, forKey: .isResizable)
		resizeAxes = try values.decodeIfPresent(WindowResizeAxes.self, forKey: .resizeAxes)
		isResizePending = try values.decodeIfPresent(Bool.self, forKey: .isResizePending) ?? false
		frame = try values.decode(CGRect.self, forKey: .frame)
		isMinimized = try values.decode(Bool.self, forKey: .isMinimized)
		isHidden = try values.decode(Bool.self, forKey: .isHidden)
		isFullscreen = try values.decode(Bool.self, forKey: .isFullscreen)
		isManaged = try values.decode(Bool.self, forKey: .isManaged)
		isBackgroundTab = try values.decode(Bool.self, forKey: .isBackgroundTab)
	}
}
