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

struct StubError: Error {}

extension DisplayInfo {
  static func stub(
    id: UInt32,
    uuid: String = "UUID",
    name: String = "Display",
    isBuiltin: Bool = false,
    isMain: Bool = false
  ) -> DisplayInfo {
    DisplayInfo(
      id: id, uuid: uuid, name: name, isBuiltin: isBuiltin, isMain: isMain,
      x: 0, y: 0, width: 1920, height: 1080)
  }
}
