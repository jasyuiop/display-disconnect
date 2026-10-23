import DisplayCore
import Testing

@testable import DisplayBackendCG

@Suite struct PrivateAPITests {
  @Test func missingSymbolThrowsUnsupportedInsteadOfCrashing() {
    do {
      _ = try PrivateAPI.symbol("DispctlOlmayanSembol", as: PrivateAPI.GetDisplayList.self)
      Issue.record("Olmayan sembol için hata bekleniyordu")
    } catch DisplayError.unsupported(let reason) {
      #expect(reason.contains("DispctlOlmayanSembol"))
    } catch {
      Issue.record("Beklenmeyen hata türü: \(error)")
    }
  }
}
