import CoreGraphics
import KumikoCore
@testable import KumikoHotkeys
import Testing

@MainActor
struct ModifierFlagsTests {
	@Test(arguments: [
		("alt", CGEventFlags.maskAlternate),
		("cmd", CGEventFlags.maskCommand),
		("ctrl", CGEventFlags.maskControl),
		("shift", CGEventFlags.maskShift),
	])
	func aggregateFlagsMatchGenericBindings(_ name: String, _ flags: CGEventFlags) throws {
		let wanted = try KeyCombo.parse("\(name) - a")
		#expect(Engine.matches(wanted.modifiers, Hotkeys.modifiers(of: flags)))
		#expect(!Engine.matches([], Hotkeys.modifiers(of: flags)))
	}

	@Test func aggregateAltDoesNotChooseASide() throws {
		let held = Hotkeys.modifiers(of: .maskAlternate)
		#expect(!Engine.matches(try KeyCombo.parse("lalt - 1").modifiers, held))
		#expect(!Engine.matches(try KeyCombo.parse("ralt - 1").modifiers, held))
	}

	@Test func physicalSidesAreStillRecognized() throws {
		let flags = CGEventFlags(rawValue: CGEventFlags.maskAlternate.rawValue | 0x40)
		#expect(Engine.matches(try KeyCombo.parse("ralt - 1").modifiers, Hotkeys.modifiers(of: flags)))
		#expect(!Engine.matches(try KeyCombo.parse("lalt - 1").modifiers, Hotkeys.modifiers(of: flags)))
	}

	@Test func aggregateAltTriggersTheWorkspaceCommand() throws {
		let combo = try KeyCombo.parse("alt - 1")
		var config = Config.Hotkeys()
		config.bindings = [combo: HotkeyAction(run: "workspace focus 1")]
		var engine = Engine(config)
		let event = KeyEvent(keyCode: combo.keyCode, modifiers: Hotkeys.modifiers(of: .maskAlternate), isDown: true)
		let (decision, effects) = engine.handle(event, frontmostApp: nil)
		#expect(decision == .swallow)
		#expect(effects == [.run("workspace focus 1")])
	}

	@Test func aModifiedLetterDoesNotTriggerAPlainBinding() throws {
		let combo = try KeyCombo.parse("h")
		var config = Config.Hotkeys()
		config.bindings = [combo: HotkeyAction(run: "window focus west")]
		var engine = Engine(config)
		let event = KeyEvent(keyCode: combo.keyCode, modifiers: Hotkeys.modifiers(of: .maskCommand), isDown: true)
		let (decision, effects) = engine.handle(event, frontmostApp: nil)
		#expect(decision == .pass)
		#expect(effects.isEmpty)
	}
}
