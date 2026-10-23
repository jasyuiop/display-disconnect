import Testing

@testable import DisplayCore

@Suite struct SwitchTests {
  private let builtin = DisplayInfo.stub(id: 1, isBuiltin: true, isMain: true)
  private let external = DisplayInfo.stub(id: 3, name: "XG27UCS")

  @Test func disableCallsBackendForExternalDisplay() throws {
    let backend = FakeBackend(displays: [builtin, external])
    try DisconnectService(backend: backend).disable(3)
    #expect(backend.recorder.calls == ["setEnabled(3, false)"])
  }

  @Test func disableUnknownIDThrowsAndDoesNotTouchBackend() {
    let backend = FakeBackend(displays: [builtin, external])
    #expect(throws: DisplayError.unknownDisplay(99)) {
      try DisconnectService(backend: backend).disable(99)
    }
    #expect(backend.recorder.calls.isEmpty)
  }

  @Test func disableLastDisplayIsRefused() {
    let backend = FakeBackend(displays: [external])
    #expect(throws: DisplayError.lastDisplay) {
      try DisconnectService(backend: backend).disable(3)
    }
    #expect(backend.recorder.calls.isEmpty)
  }

  @Test func disableBuiltinIsRefused() {
    let backend = FakeBackend(displays: [builtin, external])
    #expect(throws: DisplayError.builtinNotAllowed) {
      try DisconnectService(backend: backend).disable(1)
    }
    #expect(backend.recorder.calls.isEmpty)
  }

  @Test func enableWorksForDisplayMissingFromOnlineList() throws {
    let backend = FakeBackend(displays: [builtin])
    try DisconnectService(backend: backend).enable(3)
    #expect(backend.recorder.calls == ["setEnabled(3, true)"])
  }

  @Test func backendFailureOnDisableBecomesDisplayError() {
    let backend = FakeBackend(
      displays: [builtin, external], setEnabledFailure: StubError())
    #expect(throws: DisplayError.self) {
      try DisconnectService(backend: backend).disable(3)
    }
  }

  @Test func unsupportedFromBackendIsPreserved() {
    let backend = FakeBackend(
      displays: [builtin, external], setEnabledFailure: DisplayError.unsupported("sembol yok"))
    #expect(throws: DisplayError.unsupported("sembol yok")) {
      try DisconnectService(backend: backend).disable(3)
    }
  }
}
