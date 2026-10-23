import Testing

@testable import DisplayCore

@Suite struct DisplayMenuPresenterTests {
  @Test func rowUsesNameAsTitleAndIDAsIdentity() {
    let rows = DisplayMenuPresenter.rows([.stub(id: 3, name: "XG27UCS")])
    #expect(rows.map(\.title) == ["XG27UCS"])
    #expect(rows.map(\.id) == [3])
  }

  @Test func connectedSubtitleShowsResolution() {
    let row = DisplayMenuPresenter.rows([.stub(id: 3, width: 2560, height: 1440)])[0]
    #expect(row.subtitle.contains("2560×1440"))
    #expect(!row.isDisconnected)
  }

  @Test func subtitleMarksMainAndBuiltin() {
    let row = DisplayMenuPresenter.rows([.stub(id: 1, isBuiltin: true, isMain: true)])[0]
    #expect(row.subtitle.contains("ana ekran"))
    #expect(row.subtitle.contains("dahili"))
  }

  @Test func disconnectedRowSaysSo() {
    let row = DisplayMenuPresenter.rows([.stub(id: 3, state: .disconnected)])[0]
    #expect(row.isDisconnected)
    #expect(row.subtitle.contains("bağlantısı kesik"))
  }

  @Test func rowsKeepInputOrder() {
    let rows = DisplayMenuPresenter.rows([.stub(id: 1), .stub(id: 3), .stub(id: 7)])
    #expect(rows.map(\.id) == [1, 3, 7])
  }

  @Test func emptyInputGivesNoRows() {
    #expect(DisplayMenuPresenter.rows([]).isEmpty)
  }
}
