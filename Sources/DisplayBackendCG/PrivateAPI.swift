import CoreGraphics
import Darwin
import DisplayCore

/// Projedeki tüm private semboller yalnızca burada, çalışma anında `dlsym` ile çözülür.
/// Sembol yoksa çökme yerine `DisplayError.unsupported` döner.
enum PrivateAPI {
  /// İmza birden çok açık kaynak projeyle tutarlı (bkz. docs/ARCHITECTURE.md).
  typealias ConfigureDisplayEnabled =
    @convention(c) (CGDisplayConfigRef?, CGDirectDisplayID, Bool) -> CGError

  /// İmza doğrulanmadı (S3): yalnızca bir README'de geçiyor; CGGetOnlineDisplayList'e benzetildi.
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
      throw DisplayError.unsupported("\(name) sembolü bu macOS sürümünde bulunamadı")
    }
    return unsafeBitCast(address, to: type)
  }
}
