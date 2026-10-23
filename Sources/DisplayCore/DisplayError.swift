import Foundation

public enum DisplayError: Error, Equatable, LocalizedError {
  case unsupported(String)
  case backendFailure(String)
  case unknownDisplay(UInt32)
  case lastDisplay
  case builtinNotAllowed

  public var errorDescription: String? {
    switch self {
    case .unsupported(let reason): "Bu sistemde desteklenmiyor: \(reason)"
    case .backendFailure(let reason): "Ekran işlemi başarısız: \(reason)"
    case .unknownDisplay(let id): "\(id) kimlikli bağlı ekran yok. `dispctl list` ile bakın."
    case .lastDisplay: "Son aktif ekran kesilemez."
    case .builtinNotAllowed: "Dahili ekran kesilemez; yalnızca harici ekranlar desteklenir."
    }
  }
}
