import Foundation

@testable import DisplayCore

final class CallRecorder: @unchecked Sendable {
  private let lock = NSLock()
  private var storage: [String] = []

  var calls: [String] { lock.withLock { storage } }
  func record(_ call: String) { lock.withLock { storage.append(call) } }
}

struct FakeBackend: DisplayBackend {
  var displays: [DisplayInfo] = []
  var failure: (any Error)?
  var setEnabledFailure: (any Error)?
  let recorder = CallRecorder()

  func onlineDisplays() throws -> [DisplayInfo] {
    if let failure { throw failure }
    return displays
  }

  func setEnabled(id: UInt32, enabled: Bool) throws {
    if let setEnabledFailure { throw setEnabledFailure }
    recorder.record("setEnabled(\(id), \(enabled))")
  }
}

final class FakeStore: StateStore, @unchecked Sendable {
  private let lock = NSLock()
  private var current: DisconnectState
  var loadFailure: (any Error)?
  var saveFailure: (any Error)?

  init(_ state: DisconnectState = DisconnectState()) { current = state }

  var state: DisconnectState { lock.withLock { current } }

  func load() throws -> DisconnectState {
    if let loadFailure { throw loadFailure }
    return lock.withLock { current }
  }

  func save(_ state: DisconnectState) throws {
    if let saveFailure { throw saveFailure }
    lock.withLock { current = state }
  }
}

struct StubError: Error {}

let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

extension DisconnectService {
  /// Durumla ilgilenmeyen testler için boş, bellek içi depo.
  init(backend: any DisplayBackend) {
    self.init(backend: backend, store: FakeStore(), now: { fixedDate })
  }
}

extension DisplayInfo {
  static func stub(
    id: UInt32,
    uuid: String? = nil,
    name: String = "Display",
    isBuiltin: Bool = false,
    isMain: Bool = false,
    state: DisplayState = .connected
  ) -> DisplayInfo {
    DisplayInfo(
      id: id, uuid: uuid ?? "UUID-\(id)", name: name, isBuiltin: isBuiltin, isMain: isMain,
      x: 0, y: 0, width: 1920, height: 1080, state: state)
  }
}
