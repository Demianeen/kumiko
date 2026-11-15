import CoreGraphics
import KumikoCore
@testable import KumikoWM
import Testing

struct WindowResizeStateTests {
	private let size = CGSize(width: 700, height: 500)

	@Test func newlyResizableWindowIsCheckedAgain() {
		var state = WindowResizeState()
		state.update(settable: false, title: "Main", identifier: nil, previous: nil, size: size)
		#expect(state.axes == WindowResizeAxes(width: false, height: false))
		state.update(settable: true, title: "Main", identifier: nil, previous: size, size: size)
		#expect(state.axes == nil)
	}

	@Test func missingAXAnswerPreservesTheMeasurement() {
		var state = WindowResizeState()
		state.update(settable: true, title: "Main", identifier: nil, previous: nil, size: size)
		state.axes = WindowResizeAxes(width: false, height: true)
		state.update(settable: nil, title: "Main", identifier: nil, previous: size, size: size)
		#expect(state.axes == WindowResizeAxes(width: false, height: true))
	}

	@Test func changingWindowModeInvalidatesTheMeasurement() {
		var state = WindowResizeState()
		state.update(settable: true, title: "Main", identifier: "main", previous: nil, size: size)
		state.axes = WindowResizeAxes(width: false, height: true)
		state.update(settable: true, title: "Main", identifier: "preferences", previous: size, size: size)
		#expect(state.axes == nil)
	}

	@Test func observedResizeUpdatesTheAxis() {
		var state = WindowResizeState()
		state.update(settable: true, title: "Main", identifier: nil, previous: nil, size: size)
		state.axes = WindowResizeAxes(width: false, height: true)
		state.update(settable: true, title: "Main", identifier: nil, previous: size, size: CGSize(width: 750, height: 500))
		#expect(state.axes == WindowResizeAxes(width: true, height: true))
	}

	@Test func rejectedLayoutSizeTriggersOneRecheck() {
		var state = WindowResizeState()
		state.axes = WindowResizeAxes(width: true, height: true)
		let requested = CGSize(width: 900, height: 600)
		let recheck = state.rejected(requested, actual: size)
		#expect(recheck)
		#expect(state.needsCheck)
		#expect(state.axes == WindowResizeAxes(width: true, height: true))
		state.record(WindowResizeAxes(width: true, height: true))
		let repeated = state.rejected(requested, actual: size)
		#expect(!repeated)
	}

	@Test func acceptedLayoutSizeKeepsTheMeasurement() {
		var state = WindowResizeState()
		state.axes = WindowResizeAxes(width: true, height: true)
		let recheck = state.rejected(size, actual: size)
		#expect(!recheck)
		#expect(state.axes == WindowResizeAxes(width: true, height: true))
	}

	@Test func ordinaryTitleChangesKeepTheLayout() {
		var state = WindowResizeState()
		state.update(settable: true, title: "First page", identifier: nil, previous: nil, size: size)
		state.record(WindowResizeAxes(width: true, height: true))
		state.update(settable: true, title: "Second page", identifier: nil, previous: size, size: size)
		#expect(state.axes == WindowResizeAxes(width: true, height: true))
		#expect(!state.needsCheck)
	}

	@Test func failedRecheckKeepsTheKnownAxes() {
		var state = WindowResizeState()
		state.record(WindowResizeAxes(width: true, height: true))
		let recheck = state.rejected(CGSize(width: 900, height: 600), actual: size)
		#expect(recheck)
		state.record(nil)
		#expect(state.axes == WindowResizeAxes(width: true, height: true))
		#expect(state.needsCheck)
	}
}
