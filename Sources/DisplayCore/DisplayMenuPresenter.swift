public struct DisplayRow: Equatable, Identifiable, Sendable {
  public var id: UInt32
  public var title: String
  public var subtitle: String
  public var isDisconnected: Bool

  public init(id: UInt32, title: String, subtitle: String, isDisconnected: Bool) {
    self.id = id
    self.title = title
    self.subtitle = subtitle
    self.isDisconnected = isDisconnected
  }
}

/// Menubar listesinin satırlarını üretir; UI katmanı yalnızca bunları çizer.
public enum DisplayMenuPresenter {
  public static func rows(_ displays: [DisplayInfo]) -> [DisplayRow] {
    displays.map { display in
      var parts = ["\(display.width)×\(display.height)"]
      if display.isMain { parts.append("ana ekran") }
      if display.isBuiltin { parts.append("dahili") }
      if display.state == .disconnected { parts.append("bağlantısı kesik") }
      return DisplayRow(
        id: display.id,
        title: display.name,
        subtitle: parts.joined(separator: " · "),
        isDisconnected: display.state == .disconnected)
    }
  }
}
