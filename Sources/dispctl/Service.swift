import ArgumentParser
import DisplayBackendCG
import DisplayCore
import DisplayStorage
import Foundation

/// `DISPCTL_STATE_FILE` doluysa durum dosyası olarak o yol kullanılır (hata yollarını gerçek
/// kaydı bozmadan denemek için); yoksa `~/Library/Application Support/display-disconnect/`.
func makeService() -> DisconnectService {
  let override = ProcessInfo.processInfo.environment["DISPCTL_STATE_FILE"]
  let url =
    override.flatMap { $0.isEmpty ? nil : URL(fileURLWithPath: $0) } ?? FileStateStore.defaultURL
  return DisconnectService(backend: CGDisplayBackend(), store: FileStateStore(url: url))
}

/// `DisplayError`'ı stderr'e mesaj ve kurtarma önerisiyle yazar, kategoriye göre çıkış koduyla biter.
func reportingErrors(_ body: () throws -> Void) throws {
  do {
    try body()
  } catch let error as DisplayError {
    var message = "Error: \(error.localizedDescription)\n"
    if let suggestion = error.recoverySuggestion { message += "\(suggestion)\n" }
    FileHandle.standardError.write(Data(message.utf8))
    throw ExitCode(error.exitCode)
  }
}
