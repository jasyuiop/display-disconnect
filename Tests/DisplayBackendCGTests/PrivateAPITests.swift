import DisplayCore
import Testing

@testable import DisplayBackendCG

@Suite struct PrivateAPITests {
  @Test func missingSymbolThrowsUnsupportedInsteadOfCrashing() {
    do {
      _ = try PrivateAPI.symbol("DispctlOlmayanSembol", as: PrivateAPI.GetDisplayList.self)
      Issue.record("Expected an error for a symbol that does not exist")
    } catch DisplayError.unsupported(let reason) {
      #expect(reason.contains("DispctlOlmayanSembol"))
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }
}
