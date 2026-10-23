import Testing

@testable import DisplayCore

@Suite struct DisplayErrorTests {
  @Test func exitCodesSeparateRefusalsFromFailures() {
    let refusals: [DisplayError] = [
      .unknownDisplay(3), .notDisconnected(3), .lastDisplay, .builtinNotAllowed, .missingUUID(3),
    ]
    #expect(refusals.allSatisfy { $0.exitCode == 2 })
    #expect(DisplayError.unsupported("x").exitCode == 3)
    #expect(DisplayError.stateFailure("x").exitCode == 4)
    #expect(DisplayError.backendFailure("x").exitCode == 5)
  }

  @Test func failuresCarryRecoverySuggestionPointingToCommands() throws {
    let backend = try #require(DisplayError.backendFailure("x").recoverySuggestion)
    #expect(backend.contains("dispctl connect"))
    #expect(backend.contains("dispctl experimental enable"))

    let state = try #require(DisplayError.stateFailure("x").recoverySuggestion)
    #expect(state.contains("dispctl experimental enable"))

    #expect(DisplayError.unsupported("x").recoverySuggestion != nil)
  }

  @Test func suggestionDoesNotRecommendReplugging() throws {
    // Kablo çekip takmak kesik ekranı geri getirmedi (FAZ1.3, S-kurtarma gözlemi).
    let backend = try #require(DisplayError.backendFailure("x").recoverySuggestion)
    #expect(backend.contains("geri getirmez"))
  }

  @Test func refusalsNeedNoSuggestion() {
    #expect(DisplayError.lastDisplay.recoverySuggestion == nil)
    #expect(DisplayError.unknownDisplay(3).recoverySuggestion == nil)
  }
}
