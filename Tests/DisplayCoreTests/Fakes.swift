import Foundation

@testable import DisplayCore

final class CallRecorder: @unchecked Sendable {
  private let lock = NSLock()
  private var storage: [String] = []

  var calls: [String] { lock.withLock { storage } }
  func record(_ call: String) { lock.withLock { storage.append(call) } }
}

final class OnlineBox: @unchecked Sendable {
  private let lock = NSLock()
  private var displays: [DisplayInfo]

  init(_ displays: [DisplayInfo]) { self.displays = displays }

  var current: [DisplayInfo] { lock.withLock { displays } }
  func append(_ new: [DisplayInfo]) { lock.withLock { displays += new } }
}

struct FakeBackend: DisplayBackend {
  var failure: (any Error)?
  var setEnabledFailure: (any Error)?
  var known: [KnownDisplay]
  var knownFailure: (any Error)?
  /// `setEnabled(id, true)` çağrılınca çevrimiçi olacak ekranlar (kimlikleri eşleşirse).
  var appearsOnEnable: [DisplayInfo]
  let recorder = CallRecorder()
  private let online: OnlineBox

  init(
    displays: [DisplayInfo] = [],
    failure: (any Error)? = nil,
    setEnabledFailure: (any Error)? = nil,
    appearsOnEnable: [DisplayInfo] = [],
    known: [KnownDisplay] = [],
    knownFailure: (any Error)? = nil
  ) {
    online = OnlineBox(displays)
    self.failure = failure
    self.setEnabledFailure = setEnabledFailure
    self.appearsOnEnable = appearsOnEnable
    self.known = known
    self.knownFailure = knownFailure
  }

  func onlineDisplays() throws -> [DisplayInfo] {
    if let failure { throw failure }
    return online.current
  }

  func setEnabled(id: UInt32, enabled: Bool) throws {
    if let setEnabledFailure { throw setEnabledFailure }
    recorder.record("setEnabled(\(id), \(enabled))")
    if enabled { online.append(appearsOnEnable.filter { $0.id == id }) }
  }

  func knownDisplays() throws -> [KnownDisplay] {
    if let knownFailure { throw knownFailure }
    return known
  }

  func setOrigin(id: UInt32, x: Int, y: Int) throws {
    recorder.record("setOrigin(\(id), \(x), \(y))")
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
    self.init(backend: backend, store: FakeStore(), now: { fixedDate }, sleep: { _ in })
  }
}

extension DisplayInfo {
  static func stub(
    id: UInt32,
    uuid: String? = nil,
    name: String = "Display",
    isBuiltin: Bool = false,
    isMain: Bool = false,
    state: DisplayState = .connected,
    x: Int = 0,
    y: Int = 0,
    width: Int = 1920,
    height: Int = 1080
  ) -> DisplayInfo {
    DisplayInfo(
      id: id, uuid: uuid ?? "UUID-\(id)", name: name, isBuiltin: isBuiltin, isMain: isMain,
      x: x, y: y, width: width, height: height, state: state)
  }
}
