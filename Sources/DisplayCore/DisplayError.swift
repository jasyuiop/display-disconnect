import Foundation

public enum DisplayError: Error, Equatable, LocalizedError {
  case unsupported(String)
  case backendFailure(String)
  case stateFailure(String)
  case unknownDisplay(UInt32)
  case notDisconnected(UInt32)
  case lastDisplay
  case builtinNotAllowed
  case missingUUID(UInt32)

  public var errorDescription: String? {
    switch self {
    case .unsupported(let reason): "Bu sistemde desteklenmiyor: \(reason)"
    case .backendFailure(let reason): "Ekran işlemi başarısız: \(reason)"
    case .stateFailure(let reason): "Durum dosyası hatası: \(reason)"
    case .unknownDisplay(let id): "\(id) kimlikli bağlı ekran yok. `dispctl list` ile bakın."
    case .notDisconnected(let id):
      "\(id) kimlikli kesilmiş ekran kaydı yok. `dispctl list` ile `disconnected` olanlara bakın."
    case .lastDisplay: "Son aktif ekran kesilemez."
    case .builtinNotAllowed: "Dahili ekran kesilemez; yalnızca harici ekranlar desteklenir."
    case .missingUUID(let id):
      "\(id) kimlikli ekranın UUID'si okunamadı; geri bağlanabilmesi garanti edilemediği için kesilmedi."
    }
  }

  /// Hata kategorisine göre süreç çıkış kodu: 2 kural reddi, 3 desteklenmiyor, 4 durum dosyası,
  /// 5 ekran işlemi başarısız. (1: beklenmeyen hata, 64: ArgumentParser kullanım hatası.)
  public var exitCode: Int32 {
    switch self {
    case .unknownDisplay, .notDisconnected, .lastDisplay, .builtinNotAllowed, .missingUUID: 2
    case .unsupported: 3
    case .stateFailure: 4
    case .backendFailure: 5
    }
  }

  /// Kullanıcının bir sonraki adımı. Kural reddedilen hatalarda mesajın kendisi yeterli.
  public var recoverySuggestion: String? {
    switch self {
    case .backendFailure:
      "Ekranın durumu belirsiz olabilir: `dispctl list` ile bakın. Kesik kalan ekranı "
        + "`dispctl connect <id>`, olmazsa `dispctl experimental enable <id>` ile açın. "
        + "Kabloyu çekip takmak kesik ekranı geri getirmez."
    case .stateFailure:
      "Durum dosyası bozuksa yedeğini alıp silin (kesik ekranların kaydı kaybolur). "
        + "Kesik kalan ekranı `dispctl experimental enable <id>` ile açın."
    case .unsupported:
      "Bu özellik macOS'un private API'sine dayanır ve bu sürümde çalışmıyor olabilir. "
        + "`dispctl list` ile ekranların durumuna bakın."
    case .unknownDisplay, .notDisconnected, .lastDisplay, .builtinNotAllowed, .missingUUID:
      nil
    }
  }
}
