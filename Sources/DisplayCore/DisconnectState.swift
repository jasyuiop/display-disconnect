import Foundation

/// Kesilmeden önceki son bilinen ekran bilgisi ve kesilme zamanı.
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
  /// Dosya yoksa boş durum döner; okunamayan veya bozuk durum hata fırlatır.
  func load() throws -> DisconnectState
  func save(_ state: DisconnectState) throws
}
