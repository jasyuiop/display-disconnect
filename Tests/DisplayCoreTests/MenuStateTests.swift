import Testing

@testable import DisplayCore

@Suite struct MenuStateTests {
  @Test func listLoadedBuildsRowsAndClearsListError() {
    var state = MenuState()
    state.listFailed("liste hatası")
    state.listLoaded([.stub(id: 1, isBuiltin: true), .stub(id: 3)])
    #expect(state.rows.map(\.id) == [1, 3])
    #expect(state.errorMessage == nil)
  }

  @Test func listFailedClearsRowsAndShowsMessage() {
    var state = MenuState()
    state.listLoaded([.stub(id: 1)])
    state.listFailed("liste hatası")
    #expect(state.rows.isEmpty)
    #expect(state.errorMessage == "liste hatası")
  }

  @Test func successfulListKeepsActionError() {
    var state = MenuState()
    let started = state.beginAction(on: 3)
    #expect(started)
    state.finishAction(failure: "bağlanamadı")
    state.listLoaded([.stub(id: 1), .stub(id: 3)])
    #expect(state.errorMessage == "bağlanamadı")
  }

  @Test func actionErrorTakesPrecedenceOverListError() {
    var state = MenuState()
    state.listFailed("liste hatası")
    _ = state.beginAction(on: 3)
    state.finishAction(failure: "eylem hatası")
    #expect(state.errorMessage == "eylem hatası")
  }

  @Test func beginActionWhileBusyIsRefusedAndKeepsFirstID() {
    var state = MenuState()
    let first = state.beginAction(on: 3)
    let second = state.beginAction(on: 5)
    #expect(first)
    #expect(!second)
    #expect(state.busyID == 3)
  }

  @Test func beginActionClearsPreviousActionError() {
    var state = MenuState()
    _ = state.beginAction(on: 3)
    state.finishAction(failure: "eski hata")
    let started = state.beginAction(on: 3)
    #expect(started)
    #expect(state.errorMessage == nil)
  }

  @Test func finishActionFreesBusyID() {
    var state = MenuState()
    _ = state.beginAction(on: 3)
    state.finishAction(failure: nil)
    #expect(state.busyID == nil)
    #expect(state.errorMessage == nil)
  }

  @Test func dismissActionErrorKeepsListError() {
    var state = MenuState()
    state.listFailed("liste hatası")
    _ = state.beginAction(on: 3)
    state.finishAction(failure: "eylem hatası")
    state.dismissActionError()
    #expect(state.errorMessage == "liste hatası")
  }
}
