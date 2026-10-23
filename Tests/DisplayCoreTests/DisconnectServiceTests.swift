import Testing

@testable import DisplayCore

@Suite struct DisconnectServiceTests {
  @Test func listSortsDisplaysByID() throws {
    let backend = FakeBackend(displays: [.stub(id: 7), .stub(id: 2), .stub(id: 5)])
    let service = DisconnectService(backend: backend)
    #expect(try service.list().map(\.id) == [2, 5, 7])
  }

  @Test func listReturnsEmptyWhenNoDisplays() throws {
    let service = DisconnectService(backend: FakeBackend())
    #expect(try service.list().isEmpty)
  }

  @Test func backendFailureBecomesDisplayError() {
    let service = DisconnectService(backend: FakeBackend(failure: StubError()))
    #expect(throws: DisplayError.self) { try service.list() }
  }

  @Test func displayErrorKeepsDisplayErrorAsIs() {
    let backend = FakeBackend(failure: DisplayError.unsupported("sembol yok"))
    let service = DisconnectService(backend: backend)
    #expect(throws: DisplayError.unsupported("sembol yok")) { try service.list() }
  }
}
