import Testing

@testable import DisplayCore

@Suite struct MenuStateTests {
  @Test func listLoadedBuildsRowsAndClearsListError() {
    var state = MenuState()
    state.listFailed("list error")
    state.listLoaded([.stub(id: 1, isBuiltin: true), .stub(id: 3)])
    #expect(state.rows.map(\.id) == [1, 3])
    #expect(state.errorMessage == nil)
  }

  @Test func listFailedClearsRowsAndShowsMessage() {
    var state = MenuState()
    state.listLoaded([.stub(id: 1)])
    state.listFailed("list error")
    #expect(state.rows.isEmpty)
    #expect(state.errorMessage == "list error")
  }

  @Test func successfulListKeepsActionError() {
    var state = MenuState()
    let started = state.beginAction(on: 3)
    #expect(started)
    state.finishAction(failure: "connect failed")
    state.listLoaded([.stub(id: 1), .stub(id: 3)])
    #expect(state.errorMessage == "connect failed")
  }

  @Test func actionErrorTakesPrecedenceOverListError() {
    var state = MenuState()
    state.listFailed("list error")
    _ = state.beginAction(on: 3)
    state.finishAction(failure: "action error")
    #expect(state.errorMessage == "action error")
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
    state.finishAction(failure: "old error")
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
    state.listFailed("list error")
    _ = state.beginAction(on: 3)
    state.finishAction(failure: "action error")
    state.dismissActionError()
    #expect(state.errorMessage == "list error")
  }
}
