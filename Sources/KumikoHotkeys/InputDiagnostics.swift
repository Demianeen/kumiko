import Foundation

public struct InputDiagnostics: Codable, Sendable {
	public var tapEnabled = false
	public var secureInput = false
	public var mode = "default"
	public var stateResets = 0
	public var tapTimeouts = 0
	public var tapUserDisables = 0
	public var secureCallbacks = 0
	public var discardedSecureCallbacks = 0
	public var secureRegistrations = 0
	public var secureRegistrationFailures = 0
	public var lastRegistrationError: Int32?
	public var unsidedModifierEvents = 0
	public var slowCallbacks = 0
	public var maxCallbackMilliseconds = 0.0
}
