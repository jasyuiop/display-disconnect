/// The state of the menu bar window. List errors and action errors are kept apart: a successful
/// list refresh must not wipe an action error the user has not seen yet.
public struct MenuState: Equatable, Sendable {
  public private(set) var rows: [DisplayRow] = []
  /// ID of the display an action is running for; no other action starts meanwhile.
  public private(set) var busyID: UInt32?
  private var listError: String?
  private var actionError: String?

  public init() {}

  public var errorMessage: String? { actionError ?? listError }

  public mutating func listLoaded(_ displays: [DisplayInfo]) {
    rows = DisplayMenuPresenter.rows(displays)
    listError = nil
  }

  public mutating func listFailed(_ message: String) {
    rows = []
    listError = message
  }

  /// Returns `false` and changes nothing if an action is already running.
  public mutating func beginAction(on id: UInt32) -> Bool {
    guard busyID == nil else { return false }
    busyID = id
    actionError = nil
    return true
  }

  public mutating func finishAction(failure: String?) {
    busyID = nil
    actionError = failure
  }

  public mutating func dismissActionError() {
    actionError = nil
  }
}
