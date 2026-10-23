import Testing

@testable import DisplayCore

@Suite struct AppInfoTests {
  @Test func versionIsSemver() {
    let parts = AppInfo.version.split(separator: ".")
    #expect(parts.count == 3)
    #expect(parts.allSatisfy { Int($0) != nil })
  }
}
