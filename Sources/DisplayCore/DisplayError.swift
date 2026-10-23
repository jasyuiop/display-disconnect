import Foundation

public enum DisplayError: Error, Equatable, LocalizedError {
  case unsupported(String)
  case backendFailure(String)
  case stateFailure(String)
  case unknownDisplay(UInt32)
  case notDisconnected(UInt32)
  case lastDisplay
  case builtinNotAllowed
  case missingUUID(UInt32)

  public var errorDescription: String? {
    switch self {
    case .unsupported(let reason): "Not supported on this system: \(reason)"
    case .backendFailure(let reason): "Display operation failed: \(reason)"
    case .stateFailure(let reason): "State file error: \(reason)"
    case .unknownDisplay(let id):
      "No connected display with ID \(id). Run `dispctl list` to see the available IDs."
    case .notDisconnected(let id):
      "No disconnected display recorded with ID \(id). Run `dispctl list` and look for "
        + "`disconnected` entries."
    case .lastDisplay: "The last active display cannot be disconnected."
    case .builtinNotAllowed:
      "The built-in display cannot be disconnected; only external displays are supported."
    case .missingUUID(let id):
      "The UUID of display \(id) could not be read. It was not disconnected because "
        + "reconnecting it could not be guaranteed."
    }
  }

  /// Process exit code by error category: 2 rule refusal, 3 unsupported, 4 state file,
  /// 5 display operation failed. (1: unexpected error, 64: ArgumentParser usage error.)
  public var exitCode: Int32 {
    switch self {
    case .unknownDisplay, .notDisconnected, .lastDisplay, .builtinNotAllowed, .missingUUID: 2
    case .unsupported: 3
    case .stateFailure: 4
    case .backendFailure: 5
    }
  }

  /// What the user can do next. For refusals the message itself is enough.
  public var recoverySuggestion: String? {
    switch self {
    case .backendFailure:
      "The display state may be uncertain: check `dispctl list`. Bring back a display that stayed "
        + "disconnected with `dispctl connect <id>`, or `dispctl experimental enable <id>` if that "
        + "fails. Replugging the cable does not reliably bring a disconnected display back."
    case .stateFailure:
      "If the state file is corrupt, back it up and delete it (the records of disconnected "
        + "displays are lost). Bring back a display that stayed disconnected with "
        + "`dispctl experimental enable <id>`."
    case .unsupported:
      "This feature relies on a private macOS API that may not work on this macOS version. "
        + "Check the display state with `dispctl list`."
    case .unknownDisplay, .notDisconnected, .lastDisplay, .builtinNotAllowed, .missingUUID:
      nil
    }
  }
}
