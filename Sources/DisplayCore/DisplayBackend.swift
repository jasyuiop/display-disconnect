/// Kesik olanlar dahil, sistemin bildiği bir ekran: kimlik ve UUID.
public struct KnownDisplay: Equatable, Sendable {
  public var id: UInt32
  public var uuid: String

  public init(id: UInt32, uuid: String) {
    self.id = id
    self.uuid = uuid
  }
}

public protocol DisplayBackend: Sendable {
  /// Sistemde şu an çevrimiçi olan ekranlar. Sıra garanti edilmez.
  func onlineDisplays() throws -> [DisplayInfo]

  /// Ekranı layout'tan çıkarır (`enabled == false`) veya geri ekler. Güvenlik denetimi yapmaz;
  /// bu `DisconnectService`'in işidir.
  func setEnabled(id: UInt32, enabled: Bool) throws

  /// Kesik ekranlar dahil bilinen tüm ekranlar (private API). Kullanılamıyorsa hata fırlatır.
  func knownDisplays() throws -> [KnownDisplay]

  /// Çevrimiçi bir ekranın layout konumunu ayarlar.
  func setOrigin(id: UInt32, x: Int, y: Int) throws
}
