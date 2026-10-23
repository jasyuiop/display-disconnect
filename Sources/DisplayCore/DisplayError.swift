import Foundation

public enum DisplayError: Error, Equatable, LocalizedError {
  case unsupported(String)
  case backendFailure(String)
  case stateFailure(String)
  case unknownDisplay(UInt32)
  case lastDisplay
  case builtinNotAllowed
  case missingUUID(UInt32)

  public var errorDescription: String? {
    switch self {
    case .unsupported(let reason): "Bu sistemde desteklenmiyor: \(reason)"
    case .backendFailure(let reason): "Ekran işlemi başarısız: \(reason)"
    case .stateFailure(let reason): "Durum dosyası hatası: \(reason)"
    case .unknownDisplay(let id): "\(id) kimlikli bağlı ekran yok. `dispctl list` ile bakın."
    case .lastDisplay: "Son aktif ekran kesilemez."
    case .builtinNotAllowed: "Dahili ekran kesilemez; yalnızca harici ekranlar desteklenir."
    case .missingUUID(let id):
      "\(id) kimlikli ekranın UUID'si okunamadı; geri bağlanabilmesi garanti edilemediği için kesilmedi."
    }
  }
}
