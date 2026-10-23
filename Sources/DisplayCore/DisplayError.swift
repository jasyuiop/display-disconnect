import Foundation

public enum DisplayError: Error, Equatable, LocalizedError {
  case unsupported(String)
  case backendFailure(String)

  public var errorDescription: String? {
    switch self {
    case .unsupported(let reason): "Bu sistemde desteklenmiyor: \(reason)"
    case .backendFailure(let reason): "Ekran işlemi başarısız: \(reason)"
    }
  }
}
