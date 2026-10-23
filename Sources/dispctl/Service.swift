import ArgumentParser
import DisplayBackendCG
import DisplayCore
import DisplayStorage
import Foundation

/// If `DISPCTL_STATE_FILE` is set, that path is used as the state file (to exercise error paths
/// without touching the real record); otherwise the file lives in
/// `~/Library/Application Support/display-disconnect/`.
func makeService() -> DisconnectService {
  let override = ProcessInfo.processInfo.environment["DISPCTL_STATE_FILE"]
  let url =
    override.flatMap { $0.isEmpty ? nil : URL(fileURLWithPath: $0) } ?? FileStateStore.defaultURL
  return DisconnectService(backend: CGDisplayBackend(), store: FileStateStore(url: url))
}

/// Prints a `DisplayError` to stderr with its recovery suggestion and exits with the category's
/// exit code.
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
