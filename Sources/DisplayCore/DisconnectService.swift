import Foundation

public struct DisconnectService: Sendable {
  private let backend: any DisplayBackend
  private let store: any StateStore
  private let now: @Sendable () -> Date
  private let sleep: @Sendable (TimeInterval) -> Void

  private static let verifyAttempts = 10
  private static let verifyInterval: TimeInterval = 0.5

  public init(
    backend: any DisplayBackend,
    store: any StateStore,
    now: @escaping @Sendable () -> Date = { Date() },
    sleep: @escaping @Sendable (TimeInterval) -> Void = { Thread.sleep(forTimeInterval: $0) }
  ) {
    self.backend = backend
    self.store = store
    self.now = now
    self.sleep = sleep
  }

  /// Online displays plus recorded displays that are no longer online (disconnected). Read-only.
  public func list() throws -> [DisplayInfo] {
    let online = try onlineDisplays()
    let onlineUUIDs = Set(online.map(\.uuid))
    let disconnected = try loadState().records.map(\.display)
      .filter { !onlineUUIDs.contains($0.uuid) }
      .map { display in
        var copy = display
        copy.state = .disconnected
        return copy
      }
    return (online + disconnected).sorted { $0.id < $1.id }
  }

  /// Cuts the video signal of an external display and records it so it can be reconnected.
  /// The record is written first; if the disconnect fails, the record is rolled back.
  public func disconnect(_ id: UInt32) throws {
    let target = try validatedTarget(id)
    guard !target.uuid.isEmpty else { throw DisplayError.missingUUID(id) }

    let previous = try loadState()
    var updated = previous
    updated.records.removeAll { $0.display.uuid == target.uuid }
    updated.records.append(DisconnectedRecord(display: target, disconnectedAt: now()))
    try saveState(updated)

    do {
      try call { try backend.setEnabled(id: id, enabled: false) }
    } catch {
      // `error` is the real failure. If the rollback fails too, the record stays, but the next
      // `list` matches the online display by UUID and ignores the record.
      try? store.save(previous)
      throw error
    }
  }

  /// Reconnects a disconnected display: resolves the record by UUID, verifies that the display
  /// really came back, fixes its position if it differs from the record, and deletes the record.
  /// If the display does not come back, the record is kept.
  @discardableResult
  public func connect(_ id: UInt32) throws -> ConnectResult {
    let state = try loadState()
    guard let recorded = state.records.first(where: { $0.display.id == id })?.display else {
      throw DisplayError.notDisconnected(id)
    }

    if try onlineDisplay(uuid: recorded.uuid) != nil {
      try saveState(state, removing: recorded.uuid, afterConnect: false)
      return ConnectResult(alreadyConnected: true)
    }

    try call { try backend.setEnabled(id: currentID(of: recorded), enabled: true) }
    guard let appeared = try waitForDisplay(uuid: recorded.uuid) else {
      throw DisplayError.backendFailure(
        "The reconnect request was sent but the display did not appear within a few seconds; "
          + "the record was kept. Check `dispctl list`.")
    }

    var result = ConnectResult()
    if appeared.x != recorded.x || appeared.y != recorded.y {
      try call { try backend.setOrigin(id: appeared.id, x: recorded.x, y: recorded.y) }
      result.originRestored = true
    }
    result.sizeDiffers = appeared.width != recorded.width || appeared.height != recorded.height
    try saveState(state, removing: recorded.uuid, afterConnect: true)
    return result
  }

  /// Experimental, stateless disconnect (`dispctl experimental disable`). Same safety checks.
  public func disable(_ id: UInt32) throws {
    _ = try validatedTarget(id)
    try call { try backend.setEnabled(id: id, enabled: false) }
  }

  /// Re-adds a disconnected display. Its existence is not checked, since a disconnected display
  /// is not in the online list.
  public func enable(_ id: UInt32) throws {
    try call { try backend.setEnabled(id: id, enabled: true) }
  }

  private func validatedTarget(_ id: UInt32) throws -> DisplayInfo {
    let online = try onlineDisplays()
    guard let target = online.first(where: { $0.id == id }) else {
      throw DisplayError.unknownDisplay(id)
    }
    guard online.count > 1 else { throw DisplayError.lastDisplay }
    guard !target.isBuiltin else { throw DisplayError.builtinNotAllowed }
    return target
  }

  /// The current ID for the recorded UUID. If the private list is unavailable, the recorded ID is
  /// used; the real operation (`setEnabled`) reports its own error. IDs whose UUID does not
  /// match are never touched.
  private func currentID(of recorded: DisplayInfo) -> UInt32 {
    guard !recorded.uuid.isEmpty, let known = try? backend.knownDisplays() else {
      return recorded.id
    }
    return known.first { $0.uuid == recorded.uuid }?.id ?? recorded.id
  }

  private func onlineDisplay(uuid: String) throws -> DisplayInfo? {
    guard !uuid.isEmpty else { return nil }
    return try onlineDisplays().first { $0.uuid == uuid }
  }

  private func waitForDisplay(uuid: String) throws -> DisplayInfo? {
    for attempt in 0..<Self.verifyAttempts {
      if let display = try onlineDisplay(uuid: uuid) { return display }
      if attempt < Self.verifyAttempts - 1 { sleep(Self.verifyInterval) }
    }
    return nil
  }

  private func saveState(
    _ state: DisconnectState, removing uuid: String, afterConnect: Bool
  ) throws {
    var updated = state
    updated.records.removeAll { $0.display.uuid == uuid }
    do {
      try saveState(updated)
    } catch DisplayError.stateFailure(let reason) where afterConnect {
      throw DisplayError.stateFailure(
        "the display was reconnected but its record could not be cleared: \(reason)")
    }
  }

  private func onlineDisplays() throws -> [DisplayInfo] {
    try call { try backend.onlineDisplays().sorted { $0.id < $1.id } }
  }

  private func loadState() throws -> DisconnectState {
    do {
      return try store.load()
    } catch let error as DisplayError {
      throw error
    } catch {
      throw DisplayError.stateFailure(String(describing: error))
    }
  }

  private func saveState(_ state: DisconnectState) throws {
    do {
      try store.save(state)
    } catch let error as DisplayError {
      throw error
    } catch {
      throw DisplayError.stateFailure(String(describing: error))
    }
  }

  private func call<T>(_ body: () throws -> T) throws -> T {
    do {
      return try body()
    } catch let error as DisplayError {
      throw error
    } catch {
      throw DisplayError.backendFailure(String(describing: error))
    }
  }
}
