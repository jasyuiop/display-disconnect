public protocol DisplayBackend: Sendable {
  /// Sistemde şu an çevrimiçi olan ekranlar. Sıra garanti edilmez.
  func onlineDisplays() throws -> [DisplayInfo]
}
