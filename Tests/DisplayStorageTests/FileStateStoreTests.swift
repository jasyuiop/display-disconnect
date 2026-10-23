import DisplayCore
import Foundation
import Testing

@testable import DisplayStorage

@Suite struct FileStateStoreTests {
  private func tempURL() -> URL {
    FileManager.default.temporaryDirectory
      .appendingPathComponent("dispctl-tests-\(UUID().uuidString)")
      .appendingPathComponent("state.json")
  }

  private let record = DisconnectedRecord(
    display: DisplayInfo(
      id: 3, uuid: "U3", name: "XG27UCS", isBuiltin: false, isMain: false,
      x: 1470, y: -173, width: 2560, height: 1440),
    disconnectedAt: Date(timeIntervalSince1970: 1_700_000_000))

  @Test func missingFileLoadsEmptyState() throws {
    #expect(try FileStateStore(url: tempURL()).load() == DisconnectState())
  }

  @Test func saveThenLoadRoundTripsAndCreatesDirectories() throws {
    let url = tempURL()
    defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
    let store = FileStateStore(url: url)
    let state = DisconnectState(records: [record])
    try store.save(state)
    #expect(try store.load() == state)
  }

  @Test func corruptFileThrowsInsteadOfCrashing() throws {
    let url = tempURL()
    defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
    try FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data("{ bozuk".utf8).write(to: url)
    #expect(throws: DisplayError.self) { try FileStateStore(url: url).load() }
  }

  @Test func unwritableLocationThrowsInsteadOfCrashing() {
    let store = FileStateStore(url: URL(fileURLWithPath: "/dev/null/state.json"))
    #expect(throws: DisplayError.self) { try store.save(DisconnectState()) }
  }
}
