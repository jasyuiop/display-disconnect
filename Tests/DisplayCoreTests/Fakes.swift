@testable import DisplayCore

struct FakeBackend: DisplayBackend {
  var displays: [DisplayInfo] = []
  var failure: (any Error)?

  func onlineDisplays() throws -> [DisplayInfo] {
    if let failure { throw failure }
    return displays
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
