import CoreGraphics
import Darwin
import DisplayCore

/// Every private symbol in the project lives here and is resolved at run time with `dlsym`.
/// If a symbol is missing, `DisplayError.unsupported` is thrown instead of crashing.
enum PrivateAPI {
  /// The signature agrees with several independent open-source projects.
  typealias ConfigureDisplayEnabled =
    @convention(c) (CGDisplayConfigRef?, CGDirectDisplayID, Bool) -> CGError

  /// The signature is inferred from `CGGetOnlineDisplayList`; it is only documented in one
  /// project's README, but it behaved as expected in testing.
  typealias GetDisplayList =
    @convention(c) (UInt32, UnsafeMutablePointer<CGDirectDisplayID>?, UnsafeMutablePointer<UInt32>?)
    -> CGError

  static func configureDisplayEnabled() throws -> ConfigureDisplayEnabled {
    try symbol("CGSConfigureDisplayEnabled", as: ConfigureDisplayEnabled.self)
  }

  static func getDisplayList() throws -> GetDisplayList {
    try symbol("CGSGetDisplayList", as: GetDisplayList.self)
  }

  static func symbol<T>(_ name: String, as type: T.Type) throws -> T {
    let rtldDefault = UnsafeMutableRawPointer(bitPattern: -2)
    guard let address = dlsym(rtldDefault, name) else {
      throw DisplayError.unsupported("the symbol \(name) was not found on this macOS version")
    }
    return unsafeBitCast(address, to: type)
  }
}
