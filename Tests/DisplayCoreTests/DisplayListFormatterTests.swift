import Foundation
import Testing

@testable import DisplayCore

@Suite struct DisplayListFormatterTests {
  @Test func textShowsIDUUIDAndName() {
    let out = DisplayListFormatter.text([
      .stub(id: 3, uuid: "AAAA-BBBB", name: "LG UltraFine", isMain: true)
    ])
    #expect(out.contains("3"))
    #expect(out.contains("AAAA-BBBB"))
    #expect(out.contains("LG UltraFine"))
    #expect(out.contains("main"))
  }

  @Test func textMarksBuiltin() {
    #expect(DisplayListFormatter.text([.stub(id: 1, isBuiltin: true)]).contains("builtin"))
  }

  @Test func textMarksDisconnected() {
    #expect(
      DisplayListFormatter.text([.stub(id: 3, state: .disconnected)]).contains("disconnected"))
    #expect(!DisplayListFormatter.text([.stub(id: 3)]).contains("disconnected"))
  }

  @Test func textForEmptyListSaysSo() {
    #expect(DisplayListFormatter.text([]) == "Bağlı ekran yok.")
  }

  @Test func jsonRoundTrips() throws {
    let displays: [DisplayInfo] = [.stub(id: 1, name: "A"), .stub(id: 2, name: "B", isMain: true)]
    let data = Data(try DisplayListFormatter.json(displays).utf8)
    #expect(try JSONDecoder().decode([DisplayInfo].self, from: data) == displays)
  }

  @Test func jsonIsDeterministic() throws {
    let displays: [DisplayInfo] = [.stub(id: 1)]
    #expect(try DisplayListFormatter.json(displays) == DisplayListFormatter.json(displays))
  }
}
