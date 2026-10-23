import Foundation
import Testing

@testable import DisplayCore

@Suite struct DisconnectTests {
  private let builtin = DisplayInfo.stub(id: 1, isBuiltin: true, isMain: true)
  private let external = DisplayInfo.stub(id: 3, uuid: "U3", name: "XG27UCS")

  private func service(
    _ backend: FakeBackend, _ store: FakeStore = FakeStore()
  ) -> DisconnectService {
    DisconnectService(backend: backend, store: store, now: { fixedDate })
  }

  @Test func disconnectDisablesDisplayAndRecordsState() throws {
    let backend = FakeBackend(displays: [builtin, external])
    let store = FakeStore()
    try service(backend, store).disconnect(3)
    #expect(backend.recorder.calls == ["setEnabled(3, false)"])
    #expect(store.state.records.count == 1)
    #expect(store.state.records.first?.display == external)
    #expect(store.state.records.first?.disconnectedAt == fixedDate)
  }

  @Test func disconnectUnknownIDIsRefusedWithoutSideEffects() {
    let backend = FakeBackend(displays: [builtin, external])
    let store = FakeStore()
    #expect(throws: DisplayError.unknownDisplay(99)) { try service(backend, store).disconnect(99) }
    #expect(backend.recorder.calls.isEmpty)
    #expect(store.state.records.isEmpty)
  }

  @Test func disconnectLastDisplayIsRefusedWithoutSideEffects() {
    let backend = FakeBackend(displays: [external])
    let store = FakeStore()
    #expect(throws: DisplayError.lastDisplay) { try service(backend, store).disconnect(3) }
    #expect(backend.recorder.calls.isEmpty)
    #expect(store.state.records.isEmpty)
  }

  @Test func disconnectBuiltinIsRefusedWithoutSideEffects() {
    let backend = FakeBackend(displays: [builtin, external])
    let store = FakeStore()
    #expect(throws: DisplayError.builtinNotAllowed) { try service(backend, store).disconnect(1) }
    #expect(backend.recorder.calls.isEmpty)
    #expect(store.state.records.isEmpty)
  }

  @Test func disconnectRefusesDisplayWithoutUUID() {
    let noUUID = DisplayInfo.stub(id: 3, uuid: "")
    let backend = FakeBackend(displays: [builtin, noUUID])
    let store = FakeStore()
    #expect(throws: DisplayError.self) { try service(backend, store).disconnect(3) }
    #expect(backend.recorder.calls.isEmpty)
    #expect(store.state.records.isEmpty)
  }

  @Test func backendFailureRollsBackRecordedState() {
    let backend = FakeBackend(displays: [builtin, external], setEnabledFailure: StubError())
    let store = FakeStore()
    #expect(throws: DisplayError.self) { try service(backend, store).disconnect(3) }
    #expect(store.state.records.isEmpty)
  }

  @Test func saveFailureMeansDisplayIsNeverDisabled() {
    let backend = FakeBackend(displays: [builtin, external])
    let store = FakeStore()
    store.saveFailure = StubError()
    #expect(throws: DisplayError.self) { try service(backend, store).disconnect(3) }
    #expect(backend.recorder.calls.isEmpty)
  }

  @Test func loadFailureMeansDisplayIsNeverDisabled() {
    let backend = FakeBackend(displays: [builtin, external])
    let store = FakeStore()
    store.loadFailure = StubError()
    #expect(throws: DisplayError.self) { try service(backend, store).disconnect(3) }
    #expect(backend.recorder.calls.isEmpty)
  }

  @Test func disconnectingAgainReplacesRecordWithSameUUID() throws {
    let stale = DisconnectedRecord(display: .stub(id: 9, uuid: "U3"), disconnectedAt: .distantPast)
    let store = FakeStore(DisconnectState(records: [stale]))
    try service(FakeBackend(displays: [builtin, external]), store).disconnect(3)
    #expect(store.state.records.map(\.display.id) == [3])
  }

  @Test func listIncludesRecordedDisconnectedDisplay() throws {
    let record = DisconnectedRecord(display: external, disconnectedAt: fixedDate)
    let store = FakeStore(DisconnectState(records: [record]))
    let result = try service(FakeBackend(displays: [builtin]), store).list()
    #expect(result.map(\.id) == [1, 3])
    #expect(result.map(\.state) == [.connected, .disconnected])
  }

  @Test func listIgnoresRecordWhoseUUIDIsOnlineAgain() throws {
    let record = DisconnectedRecord(display: external, disconnectedAt: fixedDate)
    let store = FakeStore(DisconnectState(records: [record]))
    let result = try service(FakeBackend(displays: [builtin, external]), store).list()
    #expect(result.map(\.id) == [1, 3])
    #expect(result.map(\.state) == [.connected, .connected])
  }

  @Test func disconnectedDisplaysDoNotCountAsActiveForLastDisplayRule() {
    let other = DisplayInfo.stub(id: 5, uuid: "U5")
    let record = DisconnectedRecord(display: other, disconnectedAt: fixedDate)
    let store = FakeStore(DisconnectState(records: [record]))
    let backend = FakeBackend(displays: [external])
    #expect(throws: DisplayError.lastDisplay) { try service(backend, store).disconnect(3) }
  }

  @Test func listFailsInsteadOfHidingCorruptState() {
    let store = FakeStore()
    store.loadFailure = StubError()
    #expect(throws: DisplayError.self) { try service(FakeBackend(), store).list() }
  }
}
