import Foundation

/// The last known display information before the disconnect, and when it happened.
public struct DisconnectedRecord: Codable, Equatable, Sendable {
  public var display: DisplayInfo
  public var disconnectedAt: Date

  public init(display: DisplayInfo, disconnectedAt: Date) {
    self.display = display
    self.disconnectedAt = disconnectedAt
  }
}

public struct DisconnectState: Codable, Equatable, Sendable {
  public var records: [DisconnectedRecord]

  public init(records: [DisconnectedRecord] = []) {
    self.records = records
  }
}

public protocol StateStore: Sendable {
  /// Returns an empty state if nothing is stored; throws if the stored state is unreadable or
  /// corrupt.
  func load() throws -> DisconnectState
  func save(_ state: DisconnectState) throws
}
