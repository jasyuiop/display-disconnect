import DisplayCore
import Foundation

/// Keeps the state in a JSON file. A missing file is an empty state; a corrupt or unwritable
/// file is an error.
public struct FileStateStore: StateStore {
  public let url: URL

  public init(url: URL) {
    self.url = url
  }

  /// `~/Library/Application Support/display-disconnect/state.json`
  public static var defaultURL: URL {
    URL.applicationSupportDirectory
      .appendingPathComponent("display-disconnect", isDirectory: true)
      .appendingPathComponent("state.json")
  }

  public func load() throws -> DisconnectState {
    guard FileManager.default.fileExists(atPath: url.path) else { return DisconnectState() }
    do {
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601
      return try decoder.decode(DisconnectState.self, from: Data(contentsOf: url))
    } catch {
      throw DisplayError.stateFailure("\(url.path) could not be read or is corrupt: \(error)")
    }
  }

  public func save(_ state: DisconnectState) throws {
    do {
      let encoder = JSONEncoder()
      encoder.dateEncodingStrategy = .iso8601
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      try FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
      try encoder.encode(state).write(to: url, options: .atomic)
    } catch {
      throw DisplayError.stateFailure("\(url.path) could not be written: \(error)")
    }
  }
}
