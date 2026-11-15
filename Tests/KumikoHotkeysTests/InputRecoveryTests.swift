import CoreGraphics
import Foundation
import KumikoCore
@testable import KumikoHotkeys
import Testing

@MainActor
struct InputRecoveryTests {
	private func config() throws -> Config.Hotkeys {
		var config = Config.Hotkeys()
		config.bindings = [try KeyCombo.parse("alt - 1"): HotkeyAction(run: "workspace focus 1")]
		config.global = [try KeyCombo.parse("cmd + ctrl - m"): HotkeyAction(mode: "move")]
		config.modes = ["move": [:]]
		return config
	}

	private func event(_ keyCode: CGKeyCode, flags: CGEventFlags = []) throws -> CGEvent {
		let event = try #require(CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true))
		event.flags = flags
		return event
	}

	@Test func recoveryResetsBothInputHandlers() throws {
		let hotkeys = Hotkeys(bus: EventBus(), config: try config(), run: { _ in .success() })
		var resets = 0
		hotkeys.resetPassthrough = { resets += 1 }
		#expect(!hotkeys.handle(.keyDown, try event(0x2E, flags: [.maskCommand, .maskControl])))
		#expect(hotkeys.mode == "move")
		#expect(hotkeys.handle(.tapDisabledByTimeout, try event(0)))
		#expect(hotkeys.mode == "default")
		#expect(resets == 1)
		#expect(hotkeys.diagnostics.tapTimeouts == 1)
	}

	@Test func secureInputTransitionsResetOnceEach() throws {
		let hotkeys = Hotkeys(bus: EventBus(), config: try config(), run: { _ in .success() })
		var resets = 0
		hotkeys.resetPassthrough = { resets += 1 }
		hotkeys.refreshSecureHotkeys(secureInput: true)
		hotkeys.refreshSecureHotkeys(secureInput: true)
		#expect(resets == 1)
		hotkeys.refreshSecureHotkeys(secureInput: false)
		#expect(resets == 2)
	}

	@Test func pausedInputDropsItsOldState() throws {
		let hotkeys = Hotkeys(bus: EventBus(), config: try config(), run: { _ in .success() })
		var resets = 0
		hotkeys.resetPassthrough = { resets += 1 }
		_ = hotkeys.handle(.keyDown, try event(0x2E, flags: [.maskCommand, .maskControl]))
		hotkeys.isPaused = true
		#expect(hotkeys.mode == "default")
		#expect(resets == 1)
		#expect(hotkeys.handle(.keyDown, try event(0)))
	}

	@Test func recoveryDiscardsQueuedWorkspaceCommands() async throws {
		var commands: [[String]] = []
		let hotkeys = Hotkeys(bus: EventBus(), config: try config(), run: { commands.append($0); return .success() })
		_ = hotkeys.handle(.keyDown, try event(0x12, flags: .maskAlternate))
		_ = hotkeys.handle(.tapDisabledByTimeout, try event(0))
		await withCheckedContinuation { continuation in DispatchQueue.main.async { continuation.resume() } }
		#expect(commands.isEmpty)
	}

	@Test func recoveryDoesNotPublishAQueuedOldMode() async throws {
		let bus = EventBus()
		var modes: [String] = []
		bus.subscribe { if case let .hotkeyModeChanged(mode) = $0 { modes.append(mode) } }
		let hotkeys = Hotkeys(bus: bus, config: try config(), run: { _ in .success() })
		_ = hotkeys.handle(.keyDown, try event(0x2E, flags: [.maskCommand, .maskControl]))
		_ = hotkeys.handle(.tapDisabledByTimeout, try event(0))
		await withCheckedContinuation { continuation in DispatchQueue.main.async { continuation.resume() } }
		#expect(modes == ["default"])
	}
}
