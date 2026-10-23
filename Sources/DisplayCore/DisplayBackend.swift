public protocol DisplayBackend: Sendable {
  /// Sistemde şu an çevrimiçi olan ekranlar. Sıra garanti edilmez.
  func onlineDisplays() throws -> [DisplayInfo]

  /// Ekranı layout'tan çıkarır (`enabled == false`) veya geri ekler. Güvenlik denetimi yapmaz;
  /// bu `DisconnectService`'in işidir.
  func setEnabled(id: UInt32, enabled: Bool) throws
}
