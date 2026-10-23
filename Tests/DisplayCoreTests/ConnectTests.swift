import Foundation
import Testing

@testable import DisplayCore

@Suite struct ConnectTests {
  private let builtin = DisplayInfo.stub(id: 1, isBuiltin: true, isMain: true)
  private let external = DisplayInfo.stub(id: 3, uuid: "U3", name: "XG27UCS", x: 1470, y: -173)

  private func record(_ display: DisplayInfo) -> DisconnectedRecord {
    DisconnectedRecord(display: display, disconnectedAt: fixedDate)
  }

  private func service(_ backend: FakeBackend, _ store: FakeStore) -> DisconnectService {
    let recorder = backend.recorder
    return DisconnectService(
      backend: backend, store: store, now: { fixedDate }, sleep: { _ in recorder.record("sleep") })
  }

  private func calls(_ backend: FakeBackend) -> [String] {
    backend.recorder.calls.filter { $0 != "sleep" }
  }

  @Test func connectReenablesRecordedDisplayAndClearsRecord() throws {
    let backend = FakeBackend(displays: [builtin], appearsOnEnable: [external])
    let store = FakeStore(DisconnectState(records: [record(external)]))
    let result = try service(backend, store).connect(3)
    #expect(calls(backend) == ["setEnabled(3, true)"])
    #expect(store.state.records.isEmpty)
    #expect(result == ConnectResult())
  }

  @Test func connectWithoutRecordIsRefusedWithoutSideEffects() {
    let backend = FakeBackend(displays: [builtin])
    let store = FakeStore()
    #expect(throws: DisplayError.notDisconnected(99)) { try service(backend, store).connect(99) }
    #expect(calls(backend).isEmpty)
  }

  @Test func connectWhenAlreadyOnlineIsNoOpAndClearsRecord() throws {
    let backend = FakeBackend(displays: [builtin, external])
    let store = FakeStore(DisconnectState(records: [record(external)]))
    let result = try service(backend, store).connect(3)
    #expect(calls(backend).isEmpty)
    #expect(store.state.records.isEmpty)
    #expect(result.alreadyConnected)
  }

  @Test func connectUsesCurrentIDWhenUUIDMovedToAnotherID() throws {
    let moved = DisplayInfo.stub(id: 7, uuid: "U3", name: "XG27UCS", x: 1470, y: -173)
    let backend = FakeBackend(
      displays: [builtin], appearsOnEnable: [moved], known: [KnownDisplay(id: 7, uuid: "U3")])
    let store = FakeStore(DisconnectState(records: [record(external)]))
    try service(backend, store).connect(3)
    #expect(calls(backend) == ["setEnabled(7, true)"])
    #expect(store.state.records.isEmpty)
  }

  @Test func connectNeverTouchesKnownIDsWithOtherUUIDs() throws {
    let backend = FakeBackend(
      displays: [builtin], appearsOnEnable: [external],
      known: [KnownDisplay(id: 2, uuid: "BASKA"), KnownDisplay(id: 3, uuid: "U3")])
    let store = FakeStore(DisconnectState(records: [record(external)]))
    try service(backend, store).connect(3)
    #expect(calls(backend) == ["setEnabled(3, true)"])
  }

  @Test func connectFallsBackToRecordedIDWhenKnownDisplaysUnavailable() throws {
    let backend = FakeBackend(
      displays: [builtin], appearsOnEnable: [external],
      knownFailure: DisplayError.unsupported("sembol yok"))
    let store = FakeStore(DisconnectState(records: [record(external)]))
    try service(backend, store).connect(3)
    #expect(calls(backend) == ["setEnabled(3, true)"])
  }

  @Test func connectFailsAndKeepsRecordWhenDisplayNeverAppears() {
    let backend = FakeBackend(displays: [builtin])
    let store = FakeStore(DisconnectState(records: [record(external)]))
    #expect(throws: DisplayError.self) { try service(backend, store).connect(3) }
    #expect(store.state.records.count == 1)
    #expect(backend.recorder.calls.contains("sleep"))
  }

  @Test func backendFailureKeepsRecord() {
    let backend = FakeBackend(displays: [builtin], setEnabledFailure: StubError())
    let store = FakeStore(DisconnectState(records: [record(external)]))
    #expect(throws: DisplayError.self) { try service(backend, store).connect(3) }
    #expect(store.state.records.count == 1)
  }

  @Test func connectRestoresOriginWhenItDiffers() throws {
    let wrongPlace = DisplayInfo.stub(id: 3, uuid: "U3", name: "XG27UCS", x: 100, y: 0)
    let backend = FakeBackend(displays: [builtin], appearsOnEnable: [wrongPlace])
    let store = FakeStore(DisconnectState(records: [record(external)]))
    let result = try service(backend, store).connect(3)
    #expect(calls(backend) == ["setEnabled(3, true)", "setOrigin(3, 1470, -173)"])
    #expect(result.originRestored)
    #expect(!result.sizeDiffers)
  }

  @Test func connectReportsSizeMismatchWithoutChangingIt() throws {
    let smaller = DisplayInfo.stub(
      id: 3, uuid: "U3", name: "XG27UCS", x: 1470, y: -173, width: 1280, height: 720)
    let backend = FakeBackend(displays: [builtin], appearsOnEnable: [smaller])
    let store = FakeStore(DisconnectState(records: [record(external)]))
    let result = try service(backend, store).connect(3)
    #expect(calls(backend) == ["setEnabled(3, true)"])
    #expect(result.sizeDiffers)
    #expect(!result.originRestored)
  }

  @Test func saveFailureAfterConnectIsReportedAsStateFailure() {
    let backend = FakeBackend(displays: [builtin], appearsOnEnable: [external])
    let store = FakeStore(DisconnectState(records: [record(external)]))
    store.saveFailure = StubError()
    #expect(throws: DisplayError.self) { try service(backend, store).connect(3) }
    #expect(calls(backend) == ["setEnabled(3, true)"])
  }

  @Test func loadFailureMeansNothingIsEnabled() {
    let backend = FakeBackend(displays: [builtin], appearsOnEnable: [external])
    let store = FakeStore()
    store.loadFailure = StubError()
    #expect(throws: DisplayError.self) { try service(backend, store).connect(3) }
    #expect(calls(backend).isEmpty)
  }
}
